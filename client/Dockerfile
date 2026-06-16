# Stage 1 - Build React App
FROM node:20-alpine AS builder

# ✅ Add this line right below FROM to catch the environment instruction smoothly
ARG GODEBUG=asyncpreemptoff=1
ENV GODEBUG=$GODEBUG

WORKDIR /app
COPY package*.json ./
RUN npm ci
COPY . .
RUN npm run build

# Stage 2 - Nginx Production
FROM nginx:1.31-alpine
RUN rm -rf /usr/share/nginx/html/*
COPY --from=builder /app/dist /usr/share/nginx/html
COPY nginx.conf /etc/nginx/conf.d/default.conf
COPY entrypoint.sh /entrypoint.sh
RUN chmod +x /entrypoint.sh
EXPOSE 80
ENTRYPOINT ["/entrypoint.sh"]
CMD ["nginx", "-g", "daemon off;"]