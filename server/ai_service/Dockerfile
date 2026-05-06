# FROM python:3.10-slim-buster

# WORKDIR /app

# COPY . /app

# RUN pip install --no-cache-dir --upgrade pip setuptools wheel
# RUN pip install --no-cache-dir -r requirements.txt

# EXPOSE 8007

# CMD ["python", "-m", "uvicorn", "ai_service.main:app", "--host", "0.0.0.0", "--port", "8007"]

FROM python:3.10-slim-buster

WORKDIR /app

COPY server/ai_service/requirements.txt .

RUN pip install --no-cache-dir --upgrade pip setuptools wheel
RUN pip install --no-cache-dir -r requirements.txt

COPY server/ai_service/ ./ai_service/
COPY server/common/ ./common/

EXPOSE 8007

CMD ["python", "-m", "uvicorn", "ai_service.main:app", "--host", "0.0.0.0", "--port", "8007"]