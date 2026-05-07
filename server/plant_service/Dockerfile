FROM python:3.10-slim-buster

WORKDIR /app

# 1. Install dependencies
# The pipeline will copy requirements.txt into this folder before building
COPY requirements.txt .
RUN pip install --no-cache-dir --upgrade pip setuptools wheel
RUN pip install --no-cache-dir -r requirements.txt

# 2. Copy the service code and the common folder 
# (Common will also be injected by the pipeline)
COPY . .

EXPOSE 8005

# Run main directly since we are now inside the service directory
CMD ["python", "-m", "uvicorn", "main:app", "--host", "0.0.0.0", "--port", "8005"]