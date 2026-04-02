FROM nginx:alpine

# 1. Clean
RUN rm -rf /usr/share/nginx/html/*

# 2. Copy the dist folder
COPY dist /usr/share/nginx/html

# 3. Copy config and entrypoint
COPY nginx.conf /etc/nginx/nginx.conf
COPY entrypoint.sh /usr/local/bin/entrypoint.sh

# 4. Permissions
RUN chmod +x /usr/local/bin/entrypoint.sh
# Ensure the nginx user can write to the config file location
RUN touch /usr/share/nginx/html/config.js && chmod 666 /usr/share/nginx/html/config.js

EXPOSE 80

# 5. Use the absolute path
ENTRYPOINT ["/usr/local/bin/entrypoint.sh"]
CMD ["nginx", "-g", "daemon off;"]