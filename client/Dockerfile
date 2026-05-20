# =========================
# STAGE 1 — Build React App
# =========================
FROM node:20-alpine AS builder

WORKDIR /app

COPY package*.json ./

RUN npm ci

COPY . .

RUN npm run build


# =========================
# STAGE 2 — NGINX Runtime
# =========================
FROM nginx:alpine

RUN rm -rf /usr/share/nginx/html/*

COPY --from=builder /app/dist /usr/share/nginx/html

COPY nginx.conf /etc/nginx/conf.d/default.conf
COPY entrypoint.sh /usr/local/bin/entrypoint.sh

RUN chmod +x /usr/local/bin/entrypoint.sh

RUN touch /usr/share/nginx/html/config.js \
    && chmod 666 /usr/share/nginx/html/config.js

HEALTHCHECK --interval=30s --timeout=3s --retries=3 \
CMD wget --no-verbose --tries=1 --spider http://localhost || exit 1

EXPOSE 80

ENTRYPOINT ["/usr/local/bin/entrypoint.sh"]

CMD ["nginx", "-g", "daemon off;"]