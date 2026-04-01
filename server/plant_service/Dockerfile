FROM python:3.10-slim-buster

WORKDIR /app

COPY . /app

RUN pip install --no-cache-dir --upgrade pip setuptools wheel
RUN pip install --no-cache-dir -r requirements.txt

EXPOSE 8005

CMD ["python", "-m", "uvicorn", "plant_service.main:app", "--host", "0.0.0.0", "--port", "8005"]