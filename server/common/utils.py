# /server/common/utils.py
import os
from fastapi.middleware.cors import CORSMiddleware

def setup_cors(app):
    cors_origins = os.getenv("CORS_ORIGINS")

    if not cors_origins:
        origins = []
    else:
        origins = [o.strip() for o in cors_origins.split(",") if o.strip()]

    app.add_middleware(
        CORSMiddleware,
        allow_origins=["*"],
        allow_credentials=True,
        allow_methods=["*"],
        allow_headers=["*"],
    )
