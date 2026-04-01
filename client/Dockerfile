# ---------- Stage 1: Build React frontend ----------
FROM node:20-alpine AS builder

WORKDIR /app/client

# Copy package.json and package-lock.json first for caching
COPY package.json package-lock.json ./

# Install dependencies
RUN npm install

# Copy all source code
COPY . .

# Build the frontend
RUN npm run build

# ---------- Stage 2: Serve with Nginx ----------
FROM nginx:alpine AS final

# Remove default static files
RUN rm -rf /usr/share/nginx/html/*

# Copy build output from builder stage
COPY --from=builder /app/client/dist /usr/share/nginx/html

# Copy custom nginx config
COPY nginx.conf /etc/nginx/nginx.conf

# Copy entrypoint script to dynamically update env variables
COPY entrypoint.sh /docker-entrypoint.sh
RUN chmod +x /docker-entrypoint.sh

# Expose port 80
EXPOSE 80

# Use entrypoint to inject dynamic env variables
ENTRYPOINT ["/docker-entrypoint.sh"]

# Start Nginx in foreground
CMD ["nginx", "-g", "daemon off;"]