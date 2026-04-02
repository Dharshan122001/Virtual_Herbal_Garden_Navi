# --- Stage 1: Build the React App ---
FROM node:20-alpine AS build-stage
WORKDIR /app
COPY package*.json ./
RUN npm install
COPY . .
RUN npm run build

# --- Stage 2: Serve with Nginx ---
FROM nginx:alpine

# 1. Clean default files
RUN rm -rf /usr/share/nginx/html/*

# 2. Copy the 'dist' folder from the build-stage
COPY --from=build-stage /app/dist /usr/share/nginx/html

# 3. Copy your custom config and entrypoint
# We overwrite the main nginx.conf as per your old file
COPY nginx.conf /etc/nginx/conf.d/default.conf
COPY entrypoint.sh /usr/local/bin/entrypoint.sh

# 4. Permissions and Setup
RUN chmod +x /usr/local/bin/entrypoint.sh
# Create the config.js for runtime environment variables
RUN touch /usr/share/nginx/html/config.js && chmod 666 /usr/share/nginx/html/config.js

EXPOSE 80

# 5. Execution
ENTRYPOINT ["/usr/local/bin/entrypoint.sh"]
CMD ["nginx", "-g", "daemon off;"]