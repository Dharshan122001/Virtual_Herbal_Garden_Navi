# FROM python:3.10-slim-buster

# WORKDIR /app

# COPY . /app

# RUN pip install --no-cache-dir --upgrade pip setuptools wheel
# RUN pip install --no-cache-dir -r requirements.txt

# EXPOSE 8005

# CMD ["python", "-m", "uvicorn", "plant_service.main:app", "--host", "0.0.0.0", "--port", "8005"]

FROM python:3.10-slim-buster

WORKDIR /app

# Paths are relative to the repository root because buildContext is '.'
COPY server/plant_service/requirements.txt .

RUN pip install --no-cache-dir --upgrade pip setuptools wheel
RUN pip install --no-cache-dir -r requirements.txt

# Copy the service and common folder specifically
COPY server/plant_service/ ./plant_service/
COPY server/common/ ./common/

EXPOSE 8005

# Run using the module path so common is importable
CMD ["python", "-m", "uvicorn", "plant_service.main:app", "--host", "0.0.0.0", "--port", "8005"]