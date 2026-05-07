FROM python:3.10-slim-buster

WORKDIR /app

# 1. Since the context is now 'server/plant_service/', 
# the requirements.txt is right here in the current folder.
COPY requirements.txt .

RUN pip install --no-cache-dir --upgrade pip setuptools wheel
RUN pip install --no-cache-dir -r requirements.txt

# 2. Copy the plant_service code into a subfolder 
# so 'import plant_service.main' works correctly
COPY . ./plant_service/

# 3. Copy the 'common' folder (which the pipeline will provide)
COPY common/ ./common/

EXPOSE 8005

# Run as a module so it can see the common folder at the same level
CMD ["python", "-m", "uvicorn", "plant_service.main:app", "--host", "0.0.0.0", "--port", "8005"]