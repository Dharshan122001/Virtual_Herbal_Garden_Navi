# ==================================
# STAGE 1 — Build Vite + React App
# ==================================
FROM node:20-alpine AS builder

WORKDIR /app

COPY package*.json ./

RUN npm ci

COPY . .

RUN npm run build


# =========================
# STAGE 2 — Runtime
# =========================
FROM python:3.10-slim

WORKDIR /app

ENV PYTHONDONTWRITEBYTECODE=1
ENV PYTHONUNBUFFERED=1

# 1. Install pip requirements for your Python web framework (FastAPI/Starlette/etc.)
# Since this image needs to run Uvicorn, you must install it here
COPY requirements.txt .
RUN pip install --no-cache-dir --upgrade pip && \
    pip install --no-cache-dir -r requirements.txt

# 2. Copy the compiled frontend assets from Stage 1 into the Python backend folder
# (Adjust "static" to match whatever folder your Python app uses to mount static files)
COPY --from=builder /app/dist ./static

# 3. Copy the rest of your backend server application code
COPY . .

# Create numeric non-root user
RUN groupadd -g 1001 appgroup && \
    useradd -u 1001 -g appgroup -s /sbin/nologin appuser

USER 1001:1001

HEALTHCHECK --interval=30s --timeout=5s --start-period=20s --retries=3 \
  CMD python -c "import os, urllib.request; urllib.request.urlopen('http://localhost:' + os.environ.get('PORT', '8000') + '/docs')" || exit 1

EXPOSE 8000

CMD ["sh", "-c", "uvicorn ${MODULE_NAME}:app --host 0.0.0.0 --port ${PORT}"]