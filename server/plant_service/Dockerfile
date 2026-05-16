FROM python:3.10-slim-buster

# Force the container runtime path mapping engine to recognize the app root natively
ENV PYTHONPATH="/app"
WORKDIR /app

# Step 1: Force system dependencies configuration loops
RUN pip install --no-cache-dir --upgrade pip setuptools wheel

# Step 2: Push requirements downstream separately to isolate layer caching
COPY requirements.txt .
RUN pip install --no-cache-dir -r requirements.txt

# Step 3: Explicitly inherit the shared library maps cleanly 
COPY common/ ./common/

# Step 4: Inject service logical configurations
COPY . .

EXPOSE 8005

CMD ["python", "-m", "uvicorn", "main:app", "--host", "0.0.0.0", "--port", "8005"]