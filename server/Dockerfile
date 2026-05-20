# =========================
# STAGE 1 — Builder
# =========================
FROM python:3.10-slim AS builder

WORKDIR /app

ENV PYTHONDONTWRITEBYTECODE=1
ENV PYTHONUNBUFFERED=1

RUN apt-get update && apt-get install -y \
    build-essential \
    gcc \
    && rm -rf /var/lib/apt/lists/*

COPY requirements.txt .

RUN pip install --upgrade pip setuptools wheel

RUN pip install --prefix=/install --no-cache-dir -r requirements.txt


# =========================
# STAGE 2 — Runtime
# =========================
FROM python:3.10-slim

WORKDIR /app

ENV PYTHONDONTWRITEBYTECODE=1
ENV PYTHONUNBUFFERED=1

COPY --from=builder /install /usr/local

COPY . .

# Non-root user
RUN adduser --disabled-password --gecos '' appuser
USER appuser

HEALTHCHECK --interval=30s --timeout=5s --start-period=20s --retries=3 \
CMD python -c "import urllib.request; urllib.request.urlopen('http://localhost:${PORT:-8000}/docs')" || exit 1

EXPOSE 8000

CMD ["sh", "-c", "uvicorn ${MODULE_NAME}:app --host 0.0.0.0 --port ${PORT}"]