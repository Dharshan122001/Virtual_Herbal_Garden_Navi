# ==================================
# STAGE 1 — Build Vite + React App
# ==================================
FROM node:20-alpine AS builder

WORKDIR /app

COPY package*.json ./

RUN npm ci

COPY . .

RUN npm run build


# ==================================
# STAGE 2 — NGINX Runtime
# ==================================
FROM nginx:alpine

# Install wget for optional debugging/healthchecks
RUN apk add --no-cache wget

# Remove default nginx static files
RUN rm -rf /usr/share/nginx/html/*

# Copy built Vite app
COPY --from=builder /app/dist /usr/share/nginx/html

# Copy nginx config
COPY nginx.conf /etc/nginx/conf.d/default.conf

# Copy startup script
COPY entrypoint.sh /usr/local/bin/entrypoint.sh

# Prepare runtime files + permissions
RUN touch /usr/share/nginx/html/config.js && \
    touch /var/run/nginx.pid && \
    chmod +x /usr/local/bin/entrypoint.sh && \
    chown -R nginx:nginx \
      /usr/share/nginx/html \
      /var/cache/nginx \
      /var/log/nginx \
      /etc/nginx \
      /var/run/nginx.pid

# Run as non-root user
USER nginx

EXPOSE 8080

ENTRYPOINT ["/usr/local/bin/entrypoint.sh"]

CMD ["nginx", "-g", "daemon off;"]