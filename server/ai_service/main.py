import os
import requests
from fastapi import FastAPI, HTTPException, UploadFile, File
from dotenv import load_dotenv

from common import schemas
from common.utils import setup_cors

# =========================
# ENV
# =========================
load_dotenv()

GROQ_API_KEY = os.getenv("GROQ_API_KEY")
PLANTNET_API_KEY = os.getenv("PLANTNET_API_KEY")

if not GROQ_API_KEY:
    raise RuntimeError("GROQ_API_KEY missing")

if not PLANTNET_API_KEY:
    raise RuntimeError("PLANTNET_API_KEY missing")

# =========================
# APP
# =========================
app = FastAPI(title="Herbal Garden - AI Service")
setup_cors(app)

# =========================
# HEALTH
# =========================
@app.get("/")
async def health():
    return {"status": "AI Service running (Groq + PlantNet)"}

# =========================
# AI CHAT (Groq)
# =========================
@app.post("/ai/chat", response_model=schemas.ChatResponse)
async def chat_with_ai(chat_request: schemas.ChatRequest):
    try:
        payload = {
            "model": "llama-3.1-8b-instant",
            "messages": [
                {
                    "role": "system",
                    "content": (
                        "You are a herbal expert assistant. "
                        "Explain plants, medicinal uses, safety, allergies, "
                        "and traditional remedies clearly and concisely."
                    )
                },
                {
                    "role": "user",
                    "content": chat_request.message
                }
            ],
            "temperature": 0.4
        }

        headers = {
            "Authorization": f"Bearer {GROQ_API_KEY}",
            "Content-Type": "application/json"
        }

        res = requests.post(
            "https://api.groq.com/openai/v1/chat/completions",
            json=payload,
            headers=headers,
            timeout=20
        )

        res.raise_for_status()
        ai_text = res.json()["choices"][0]["message"]["content"]

        return {"response": ai_text}

    except Exception as e:
        print("AI CHAT ERROR:", str(e))
        raise HTTPException(status_code=500, detail="AI chat failed")

# =========================
# PLANT IDENTIFICATION (PlantNet + Groq)
# =========================
@app.post("/ai/identify", response_model=schemas.PlantIdentificationResponse)
async def identify_plant(image: UploadFile = File(...)):
    if not image.content_type.startswith("image/"):
        raise HTTPException(status_code=400, detail="File must be an image")

    try:
        # --------------------------
        # 1️⃣ Identify via PlantNet
        # --------------------------
        image_bytes = await image.read()

        files = {
            "images": ("plant.jpg", image_bytes, image.content_type)
        }

        data = {"organs": "leaf"}

        url = f"https://my-api.plantnet.org/v2/identify/all?api-key={PLANTNET_API_KEY}"

        res = requests.post(url, files=files, data=data, timeout=30)
        res.raise_for_status()

        result = res.json()
        results = result.get("results", [])

        if not results:
            return {
                "plant_name": "Unknown Plant"
            }

        best = results[0]
        species = best.get("species", {})

        common_names = species.get("commonNames") or []
        scientific_name = species.get("scientificName", "Unknown")

        plant_name = common_names[0] if common_names else scientific_name

        return {
            "plant_name": plant_name
        }

    except Exception as e:
        print("PLANT IDENTIFY ERROR:", str(e))
        raise HTTPException(status_code=500, detail="Plant identification failed")
