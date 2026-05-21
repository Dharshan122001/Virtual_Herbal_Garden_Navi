# -----------------------------
# Stage 1 - Build React/Vite App
# -----------------------------
FROM node:20-alpine AS builder

WORKDIR /app

# Copy package files
COPY package*.json ./

# Install dependencies
RUN npm install

# Copy full source code
COPY . .

# Build Vite app
RUN npm run build

# -----------------------------
# Stage 2 - Nginx Production Server
# -----------------------------
FROM nginx:alpine

# Remove default nginx content
RUN rm -rf /usr/share/nginx/html/*

# Copy built app from builder
COPY --from=builder /app/dist /usr/share/nginx/html

# Expose nginx port
EXPOSE 80

# Start nginx
CMD ["nginx", "-g", "daemon off;"]