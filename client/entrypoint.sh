#!/bin/sh
set -e

# Use the absolute path to the nginx html folder
CONFIG_FILE="/usr/share/nginx/html/config.js"

echo "Writing config to $CONFIG_FILE"

# Create the file with the values from Azure Env Vars
cat <<EOF > $CONFIG_FILE
window.appConfig = {
  VITE_PLANT_API_URL: "$VITE_PLANT_API_URL",
  VITE_AUTH_API_URL: "$VITE_AUTH_API_URL",
  VITE_AI_API_URL: "$VITE_AI_API_URL"
};
EOF

echo "Content of $CONFIG_FILE:"
cat $CONFIG_FILE

# Start Nginx
exec "$@"