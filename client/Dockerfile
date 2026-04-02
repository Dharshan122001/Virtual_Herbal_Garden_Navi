# Stage 1: Build Stage
FROM node:20-alpine AS build-stage

# Set working directory
WORKDIR /app

# Copy package files first (to leverage Docker cache)
COPY package*.json ./

# Install dependencies
RUN npm install

# Copy the rest of the frontend source code
COPY . .

# Build the React/Vite app
RUN npm run build

# Stage 2: Production Stage (Nginx)
FROM nginx:stable-alpine

# Copy the build output from the previous stage to Nginx
# Vite usually builds into the 'dist' folder
COPY --from=build-stage /app/dist /usr/share/nginx/html

# Copy your custom nginx config (make sure this file exists in /client)
COPY nginx.conf /etc/nginx/conf.d/default.conf

# Expose port 80
EXPOSE 80

# Start Nginx
CMD ["nginx", "-g", "daemon off;"]