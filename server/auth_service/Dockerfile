# FROM python:3.10-slim-buster
# WORKDIR /app
# COPY . /app
# RUN pip install --no-cache-dir --upgrade pip setuptools wheel
# RUN pip install --no-cache-dir -r requirements.txt
# EXPOSE 8006
# CMD ["python", "-m", "uvicorn", "auth_service.main:app", "--host", "0.0.0.0", "--port", "8006"]

FROM python:3.10-slim-buster

WORKDIR /app

COPY server/auth_service/requirements.txt .

RUN pip install --no-cache-dir --upgrade pip setuptools wheel
RUN pip install --no-cache-dir -r requirements.txt

COPY server/auth_service/ ./auth_service/
COPY server/common/ ./common/

EXPOSE 8006

CMD ["python", "-m", "uvicorn", "auth_service.main:app", "--host", "0.0.0.0", "--port", "8006"]