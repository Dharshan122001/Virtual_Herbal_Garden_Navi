import os
import uuid
import datetime
from fastapi import FastAPI, Depends, HTTPException
from sqlalchemy.orm import Session
from sqlalchemy import text
from passlib.context import CryptContext
from dotenv import load_dotenv
from jose import jwt

from common.database import get_db
from common import schemas
from common.utils import setup_cors
from common.gmail_service import send_email

load_dotenv()

app = FastAPI(title="Herbal Garden - Auth Service")
setup_cors(app)

# =======================
# SECURITY CONFIG
# =======================
SECRET_KEY = os.getenv("SECRET_KEY")
ALGORITHM = os.getenv("ALGORITHM", "HS256")
pwd_context = CryptContext(schemes=["bcrypt"], deprecated="auto")
BASE_URL = os.getenv("BASE_URL", "https://virtual-herbal-garden-r1uw.onrender.com")

# =======================
# HELPERS
# =======================
def create_access_token(data: dict):
    payload = data.copy()
    payload["exp"] = datetime.datetime.utcnow() + datetime.timedelta(days=1)
    return jwt.encode(payload, SECRET_KEY, algorithm=ALGORITHM)

def hash_password(password: str) -> str:
    if len(password.encode("utf-8")) > 72:
        raise HTTPException(status_code=400, detail="Password too long")
    return pwd_context.hash(password)

def verify_password(plain: str, hashed: str) -> bool:
    if not plain or len(plain.encode("utf-8")) > 72:
        return False
    return pwd_context.verify(plain, hashed)

# =======================
# HEALTH
# =======================
@app.get("/")
async def health():
    return {"status": "Auth Service running"}

# =======================
# REGISTER
# =======================
@app.post("/auth/register")
async def register(user_data: schemas.UserCreate, db: Session = Depends(get_db)):
    exists = db.execute(
        text("SELECT 1 FROM public.users WHERE email = :e"),
        {"e": user_data.email}
    ).first()

    if exists:
        raise HTTPException(status_code=400, detail="Email already exists")

    hashed = hash_password(user_data.password)

    user = db.execute(
        text("""
            INSERT INTO public.users (email, hashed_password, first_name, last_name)
            VALUES (:email, :pw, :fn, :ln)
            RETURNING email, first_name
        """),
        {
            "email": user_data.email,
            "pw": hashed,
            "fn": user_data.first_name,
            "ln": user_data.last_name
        }
    ).mappings().first()

    db.commit()
    

    # Send welcome email (non-blocking)
    try:
        send_email(
            to=user_data.email,
            subject="Welcome to Herbal Garden 🌿",
            html=f"""
            <h3>Welcome to Herbal Garden 🌿</h3>
            <p>Your account has been created.</p>
            """
        )
    except Exception as e:
        print("Email failed:", e)

    return {
        "id": user["email"],
        "email": user["email"],
        "first_name": user["first_name"]
    }

# =======================
# LOGIN
# =======================
@app.post("/auth/login")
def login(data: schemas.UserCreate, db: Session = Depends(get_db)):
    user = db.execute(
        text("""
            SELECT email, first_name, hashed_password
            FROM public.users WHERE email = :email
        """),
        {"email": data.email}
    ).mappings().first()

    if not user or not verify_password(data.password, user["hashed_password"]):
        raise HTTPException(status_code=401, detail="Invalid credentials")

    token = create_access_token({"sub": user["email"], "id": user["email"]})

    return {
        "access_token": token,
        "user": {
            "id": user["email"],
            "email": user["email"],
            "first_name": user["first_name"]
        }
    }

# =======================
# FORGOT PASSWORD
# =======================
@app.post("/auth/forgot-password")
async def forgot_password(data: schemas.ResetCodeCreate, db: Session = Depends(get_db)):
    user = db.execute(
        text("SELECT email FROM public.users WHERE email = :e"),
        {"e": data.email}
    ).first()

    if user:
        reset_id = str(uuid.uuid4())

        db.execute(
            text("""
                INSERT INTO public.resetcode (email, "resetId", status, created_at, expired_in)
                VALUES (:email, :rid, 'pending', NOW(), INTERVAL '1 hour')
            """),
            {"email": data.email, "rid": reset_id}
        )
        db.commit()
        
        reset_link = f"{BASE_URL}/reset-password?code={reset_id}"
        try:
            send_email(
               to=data.email,
               subject="Herbal Garden – Password Reset Code",
               html=f"""
                   <h3>Password Reset</h3>
                   <p>Use the reset code below to set a new password:</p>
                   <h2 style="letter-spacing:2px">{reset_id}</h2>
                   <p>This code expires in 3 Minutes.</p>
                   <p>If you didn’t request this, you can safely ignore this email.</p> """
            )
        except Exception as e:
            print("Email failed:", e)

    # Always return success (security best practice)
    return {"message": "If the account exists, a reset email has been sent."}

# =======================
# RESET PASSWORD
# =======================
@app.post("/auth/reset-password")
async def reset_password(data: schemas.ResetCodeVerify, db: Session = Depends(get_db)):
    record = db.execute(
        text("""
            SELECT id FROM public.resetcode
            WHERE email = :email
              AND "resetId" = :rid
              AND status = 'pending'
              AND (created_at + expired_in) > NOW()
        """),
        {"email": data.email, "rid": data.resetId}
    ).mappings().first()

    if not record:
        raise HTTPException(status_code=400, detail="Invalid or expired reset code")

    new_hash = hash_password(data.new_password)

    db.execute(
        text("UPDATE public.users SET hashed_password = :p WHERE email = :e"),
        {"p": new_hash, "e": data.email}
    )

    db.execute(
        text("UPDATE public.resetcode SET status = 'used' WHERE id = :id"),
        {"id": record["id"]}
    )

    db.commit()

    return {"message": "Password updated successfully"}
