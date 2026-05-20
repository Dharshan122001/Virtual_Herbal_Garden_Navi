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
# STAGE 2 — NGINX Secure Runtime
# ==================================
FROM nginx:alpine

# 1. Clean default static assets
RUN rm -rf /usr/share/nginx/html/*

# 2. Copy compiled assets from builder stage
COPY --from=builder /app/dist /usr/share/nginx/html
COPY nginx.conf /etc/nginx/conf.d/default.conf
COPY entrypoint.sh /usr/local/bin/entrypoint.sh

# 3. Setup placeholder config file and grant permissions
RUN touch /usr/share/nginx/html/config.js && chmod +x /usr/local/bin/entrypoint.sh

# 4. Change directory ownerships to standard unprivileged 'nginx' user (UID 101)
# This allows Nginx to write temporary cache files, logs, and pid files without root
RUN chown -R nginx:nginx /usr/share/nginx/html \
                         /var/cache/nginx \
                         /var/log/nginx \
                         /etc/nginx \
                         /var/run

# 5. Switch execution context away from root completely
USER nginx

# 6. Monitor container health safely on the unprivileged port
HEALTHCHECK --interval=30s --timeout=3s --retries=3 \
CMD wget --no-verbose --tries=1 --spider http://localhost:8080 || exit 1

# Expose unprivileged port (ports under 1024 require root)
EXPOSE 8080

ENTRYPOINT ["/usr/local/bin/entrypoint.sh"]
CMD ["nginx", "-g", "daemon off;"]