FROM python:3.10-slim-buster
WORKDIR /app

# FORCE INITIAL TOOLING ASSEMBLY BEFORE COPYPASSES
RUN pip install --no-cache-dir --upgrade pip setuptools wheel

COPY requirements.txt .
RUN pip install --no-cache-dir -r requirements.txt

# ❌ REMOVED: RUN opentelemetry-bootstrap -a install

COPY . .
EXPOSE 8007

# ✅ UPDATED: Run uvicorn natively without the legacy wrapper
CMD ["python", "-m", "uvicorn", "main:app", "--host", "0.0.0.0", "--port", "8007"]