#/server/plant_service/main.py
from fastapi import FastAPI, Depends, HTTPException, Query, status
from sqlalchemy.orm import Session
from sqlalchemy import text
from typing import List, Optional

# Absolute imports from your monorepo structure
from common.database import get_db
from common import schemas
from common.utils import setup_cors

from pathlib import Path
from dotenv import load_dotenv


BASE_DIR = Path(__file__).resolve().parent.parent
env_path = BASE_DIR / ".env"
load_dotenv(dotenv_path=env_path)

# 2. Force Load


app = FastAPI(title="Herbal Garden - Plant Service")
setup_cors(app)


# --- Plant Catalog Endpoints ---
@app.get("/")
async def health_check():
    return {"status": "Plant Service is running"}

@app.get("/plants", response_model=List[schemas.Plant])
def list_plants(
    search_query: Optional[str] = Query(None, description="Search by name, description, or uses"), 
    db: Session = Depends(get_db)
):
    """Fetch all plants or filter by search query."""
    query_str = "SELECT * FROM public.plants"
    params = {}
    
    if search_query:
        # We use ARRAY_TO_STRING to search inside the 'uses' TEXT[] array in Postgres
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
    """Fetch a single plant by its ID."""
    query = text("SELECT * FROM public.plants WHERE plant_id = :id")
    result = db.execute(query, {"id": plant_id}).first()
    
    if not result:
        raise HTTPException(status_code=404, detail="Plant not found")
    return schemas.Plant(**result._asdict())

# --- Bookmark Endpoints ---

@app.get("/bookmarks/user/{email}", response_model=List[schemas.Bookmark])
def get_user_bookmarks(email: str, db: Session = Depends(get_db)):
    """Retrieve all bookmarks for a specific user email."""
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
    """Create a bookmark link between a user (email) and a plant."""
    # 1. Verify the plant exists
    plant = db.execute(
        text("SELECT 1 FROM public.plants WHERE plant_id = :pid"), 
        {"pid": bookmark.plant_id}
    ).first()
    if not plant:
        raise HTTPException(status_code=404, detail="Plant does not exist")
    
    # 2. check whether the plant is already bookamrked ?
    existing_bookmark_query = text("SELECT bookmark_id FROM public.bookmarks WHERE email = :user_mail_id AND plant_id = :plant_id;")
    existing_bookmark = db.execute(existing_bookmark_query, {
        "user_mail_id": bookmark.email,
        "plant_id": bookmark.plant_id
    }).first()
    if existing_bookmark:
        raise HTTPException(status_code=status.HTTP_409_CONFLICT, detail="This plant is already bookmarked by this user.")
    # 2. Insert bookmark (using 'user_email' to match your updated schema)
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
        # Usually happens if the unique constraint (user_email, plant_id) is violated
        raise HTTPException(status_code=status.HTTP_400_BAD_REQUEST, detail=f"Error creating bookmark: {e}")



@app.delete("/bookmarks/{email}/{plant_id}", status_code=status.HTTP_204_NO_CONTENT)
def remove_bookmark(email: str, plant_id: int, db: Session = Depends(get_db)):
    """Remove a specific bookmark."""
    query = text("DELETE FROM public.bookmarks WHERE email = :email AND plant_id = :pid RETURNING bookmark_id")
    result = db.execute(query, {"email": email, "pid": plant_id}).first()
    db.commit()
    if not result:
        raise HTTPException(status_code=404, detail="Bookmark not found for this user and plant")
    return