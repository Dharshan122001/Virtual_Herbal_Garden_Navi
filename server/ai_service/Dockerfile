FROM python:3.10-slim-buster
WORKDIR /app
COPY requirements.txt .
RUN pip install --no-cache-dir --upgrade pip setuptools wheel
RUN pip install --no-cache-dir -r requirements.txt

# ADD THIS LINE: Installs the underlying dependency shims natively into the image environment
RUN opentelemetry-bootstrap -a install

COPY . .
EXPOSE 8007
CMD ["opentelemetry-instrument", "python", "-m", "uvicorn", "main:app", "--host", "0.0.0.0", "--port", "8007"]