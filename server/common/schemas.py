from pydantic import BaseModel, HttpUrl, EmailStr
from typing import Optional, List
from datetime import datetime

class UserBase(BaseModel):
    email: EmailStr
    first_name: Optional[str] = None
    last_name: Optional[str] = None

class UserCreate(UserBase):
    password: str

class ResetCodeCreate(BaseModel):
    email: EmailStr

class ResetCodeVerify(BaseModel):
    email: EmailStr
    resetId: str
    new_password: str

class Plant(BaseModel):
    plant_id: int
    common_name: str
    scientific_name: Optional[str] = None
    description: Optional[str] = None
    uses: Optional[List[str]] = None
    region: Optional[str] = None
    plant_type: Optional[str] = None
    image_url: Optional[str] = None

    class Config:
        from_attributes = True

class BookmarkCreate(BaseModel):
    email: EmailStr
    plant_id: int

class Bookmark(BookmarkCreate):
    bookmark_id: int
    bookmarked_at: datetime

    class Config:
        from_attributes = True

class ChatRequest(BaseModel):
    message: str

class ChatResponse(BaseModel):
    response: str

class PlantIdentificationResponse(BaseModel):
    plant_name: str