# import os
# from pathlib import Path
# from dotenv import load_dotenv
# from sqlalchemy import create_engine
# from sqlalchemy.orm import sessionmaker

# # 1. Precise Path Finding
# # Path(__file__) is server/common/database.py
# # .parent.parent.parent moves up to the root folder

# BASE_DIR = Path(__file__).resolve().parent.parent
# env_path = BASE_DIR / ".env"

# # 2. Force Load
# load_dotenv(dotenv_path=env_path)

# # 3. Validation Helper
# def get_env_variable(var_name):
#     value = os.getenv(var_name)
#     if value is None:
#         raise ValueError(f"CRITICAL ERROR: {var_name} is missing from .env file at {env_path}")
#     return value.strip().replace('"', '').replace("'", "") # Clean quotes/spaces

# # 4. Fetch and Validate
# user = get_env_variable("POSTGRES_USER")
# password = get_env_variable("POSTGRES_PASSWORD")
# db_name = get_env_variable("POSTGRES_DB")
# host = get_env_variable("POSTGRES_HOST")
# port = get_env_variable("POSTGRES_PORT")

# # 5. Build URL
# DATABASE_URL = f"postgresql://{user}:{password}@{host}:{port}/{db_name}"

# print(f"--- Database connection string initialized for: {db_name} ---")

# engine = create_engine(DATABASE_URL, pool_pre_ping=True)
# SessionLocal = sessionmaker(autocommit=False, autoflush=False, bind=engine)

# def get_db():
#     db = SessionLocal()
#     try:
#         yield db
#     finally:
#         db.close()
import os
from sqlalchemy import create_engine
from sqlalchemy.orm import sessionmaker

DATABASE_URL = os.getenv("DATABASE_URL")

engine = create_engine(
    DATABASE_URL,
    pool_pre_ping=True
)

SessionLocal = sessionmaker(
    autocommit=False,
    autoflush=False,
    bind=engine
)

def get_db():
    db = SessionLocal()
    try:
        yield db
    finally:
        db.close()