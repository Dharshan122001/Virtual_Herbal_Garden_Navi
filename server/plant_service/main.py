from fastapi import FastAPI, Depends, HTTPException, Query, status
from sqlalchemy.orm import Session
from sqlalchemy import text
from typing import List, Optional
import os
import io
from fastapi.responses import StreamingResponse
from pathlib import Path
from dotenv import load_dotenv

from common.database import get_db
from common import schemas
from common.utils import setup_cors
from common.otel import init_tracer, instrument_app

BASE_DIR = Path(__file__).resolve().parent.parent
env_path = BASE_DIR / ".env"
load_dotenv(dotenv_path=env_path)

# --- Initialize OpenTelemetry ---
init_tracer("plant-service")

app = FastAPI(title="Herbal Garden - Plant Service")
setup_cors(app)

# Instrument lifecycle pipelines with explicit contextual tracing configuration
instrument_app(app)

@app.get("/api/v1/test-deploy")
async def test_api():
    return {
        "message": "GitOps Pipeline Success!",
        "service": "Plant Service",
        "version": "v1.0.1"
    }

@app.get("/")
async def health_check():
    return {"status": "Plant Service is running"}

@app.get("/plants", response_model=List[schemas.Plant])
def list_plants(
    search_query: Optional[str] = Query(None, description="Search by name, description, or uses"), 
    db: Session = Depends(get_db)
):
    query_str = "SELECT * FROM public.plants"
    params = {}
    
    if search_query:
        query_str += """ 
            WHERE common_name ILIKE :search 
            OR scientific_name ILIKE :search 
            OR description ILIKE :search
            OR ARRAY_TO_STRING(uses, ' ') ILIKE :search
        """
        params["search"] = f"%{search_query}%"
    
    result = db.execute(text(query_str), params).fetchall()
    parsed_plants = []
    for row in result:
        plant_dict = row._asdict()
        parsed_plants.append(schemas.Plant(**plant_dict))

    return parsed_plants

@app.get("/plants/{plant_id}", response_model=schemas.Plant)
def get_plant_detail(plant_id: int, db: Session = Depends(get_db)):
    query = text("SELECT * FROM public.plants WHERE plant_id = :id")
    result = db.execute(query, {"id": plant_id}).first()
    
    if not result:
        raise HTTPException(status_code=404, detail="Plant not found")
    return schemas.Plant(**result._asdict())

@app.get("/bookmarks/user/{email}", response_model=List[schemas.Bookmark])
def get_user_bookmarks(email: str, db: Session = Depends(get_db)):
    query = text("""
        SELECT bookmark_id, email, plant_id, bookmarked_at 
        FROM public.bookmarks WHERE email = :email
    """)
    result = db.execute(query, {"email": email}).fetchall()
    if not result:
        return []
    return [schemas.Bookmark(**row._asdict()) for row in result]

@app.post("/bookmarks/", response_model=schemas.Bookmark)
def add_bookmark(bookmark: schemas.BookmarkCreate, db: Session = Depends(get_db)):
    plant = db.execute(
        text("SELECT 1 FROM public.plants WHERE plant_id = :pid"), 
        {"pid": bookmark.plant_id}
    ).first()
    if not plant:
        raise HTTPException(status_code=404, detail="Plant does not exist")
    
    existing_bookmark_query = text("SELECT bookmark_id FROM public.bookmarks WHERE email = :user_mail_id AND plant_id = :plant_id;")
    existing_bookmark = db.execute(existing_bookmark_query, {
        "user_mail_id": bookmark.email,
        "plant_id": bookmark.plant_id
    }).first()
    if existing_bookmark:
        raise HTTPException(status_code=status.HTTP_409_CONFLICT, detail="This plant is already bookmarked by this user.")
        
    query = text("""
        INSERT INTO public.bookmarks (email, plant_id)
        VALUES (:email, :pid)
        RETURNING bookmark_id, email, plant_id, bookmarked_at;
    """)
    try:
        result = db.execute(query, {"email": bookmark.email, "pid": bookmark.plant_id}).first()
        db.commit()
        if result:
            return schemas.Bookmark(**result._asdict())
        raise HTTPException(status_code=status.HTTP_500_INTERNAL_SERVER_ERROR, detail="Bookmark could not be created.")
        
    except Exception as e:
        db.rollback()
        raise HTTPException(status_code=status.HTTP_400_BAD_REQUEST, detail=f"Error creating bookmark: {e}")

@app.delete("/bookmarks/{email}/{plant_id}", status_code=status.HTTP_204_NO_CONTENT)
def remove_bookmark(email: str, plant_id: int, db: Session = Depends(get_db)):
    query = text("DELETE FROM public.bookmarks WHERE email = :email AND plant_id = :pid RETURNING bookmark_id")
    result = db.execute(query, {"email": email, "pid": plant_id}).first()
    db.commit()
    if not result:
        raise HTTPException(status_code=404, detail="Bookmark not found for this user and plant")
    return

@app.get("/system/backup-db")
def backup_database(db: Session = Depends(get_db)):
    try:
        result = db.execute(text(
            "SELECT table_name FROM information_schema.tables WHERE table_schema = 'public'"
        ))
        tables = [row[0] for row in result.fetchall()]
        
        output = io.StringIO()
        output.write("-- Emergency Data Rescue Dump\n")
        
        for table in tables:
            output.write(f"\n-- Table: {table}\n")
            rows = db.execute(text(f"SELECT * FROM public.{table}")).fetchall()
            
            if rows:
                columns = rows[0]._fields
                for row in rows:
                    vals = [f"'{str(v)}'" if v is not None else "NULL" for v in row]
                    insert_stmt = f"INSERT INTO {table} ({', '.join(columns)}) VALUES ({', '.join(vals)});\n"
                    output.write(insert_stmt)
                    
        output.seek(0)
        return StreamingResponse(
            io.BytesIO(output.getvalue().encode()),
            media_type="application/sql",
            headers={"Content-Disposition": "attachment; filename=emergency_dump.sql"}
        )

    except Exception as e:
        return {"error": f"Python-only backup failed: {str(e)}"}