FROM python:3.10-slim-buster

# --- NEW: Install PostgreSQL Client ---
RUN apt-get update && apt-get install -y \
    postgresql-client \
    && rm -rf /var/lib/apt/lists/*

WORKDIR /app/server/   
COPY . /app/server/

RUN pip install --no-cache-dir --upgrade pip setuptools wheel
RUN pip install --no-cache-dir -r requirements.txt

WORKDIR /app
EXPOSE 8005

CMD ["python", "-m", "uvicorn", "server.main:app", "--host", "0.0.0.0", "--port", "8005", "--app-dir", "."]