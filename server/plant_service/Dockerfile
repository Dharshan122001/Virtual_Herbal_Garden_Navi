FROM python:3.10-slim-buster

WORKDIR /app

# 1. Local path - requirements.txt is now in the current folder
COPY requirements.txt .

RUN pip install --no-cache-dir --upgrade pip setuptools wheel
RUN pip install --no-cache-dir -r requirements.txt

# 2. Copy the service code into its package subfolder
COPY . ./plant_service/

# 3. Copy the 'common' folder (injected by the pipeline script)
COPY common/ ./common/

EXPOSE 8005

# Run using module path
CMD ["python", "-m", "uvicorn", "plant_service.main:app", "--host", "0.0.0.0", "--port", "8005"]