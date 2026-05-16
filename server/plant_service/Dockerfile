FROM python:3.10-slim-buster
WORKDIR /app

RUN pip install --no-cache-dir --upgrade pip setuptools wheel

COPY requirements.txt .
RUN pip install --no-cache-dir -r requirements.txt

COPY . .
EXPOSE 8005

# ✅ UPDATED: Run uvicorn natively without the legacy wrapper
CMD ["python", "-m", "uvicorn", "main:app", "--host", "0.0.0.0", "--port", "8005"]