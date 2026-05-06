# --- Simplified Production Nginx Dockerfile ---
FROM nginx:alpine

# 1. Clean default files
RUN rm -rf /usr/share/nginx/html/*

# 2. Copy the 'dist' folder we just built locally
COPY dist /usr/share/nginx/html

# 3. Copy your custom config and entrypoint
COPY nginx.conf /etc/nginx/conf.d/default.conf
COPY entrypoint.sh /usr/local/bin/entrypoint.sh

# 4. Permissions and Setup
RUN chmod +x /usr/local/bin/entrypoint.sh
RUN touch /usr/share/nginx/html/config.js && chmod 666 /usr/share/nginx/html/config.js

EXPOSE 80

ENTRYPOINT ["/usr/local/bin/entrypoint.sh"]
CMD ["nginx", "-g", "daemon off;"]