FROM python:3.10-slim-buster
WORKDIR /app

# FORCE INITIAL TOOLING ASSEMBLY BEFORE COPYPASSES
RUN pip install --no-cache-dir --upgrade pip setuptools wheel

COPY requirements.txt .
RUN pip install --no-cache-dir -r requirements.txt
RUN opentelemetry-bootstrap -a install

COPY . .
EXPOSE 8005
CMD ["opentelemetry-instrument", "python", "-m", "uvicorn", "main:app", "--host", "0.0.0.0", "--port", "8005"]