#!/bin/sh

# Replace placeholder in JavaScript files
# Find all .js files in the Nginx html directory
# and replace the placeholder __VITE_API_BASE_URL_PLACEHOLDER__ with the actual VITE_API_BASE_URL environment variable.
# Ensure that the placeholder used here exactly matches what you expect in your built JS files.
# Vite often inlines env vars, so you might need to adjust based on how Vite bundles.
# A more robust approach would be to have your app fetch the config from a separate JSON endpoint
# or for the entrypoint to generate a JS config file on the fly.
# For a simple string replacement, you might look for a specific string like 'VITE_API_BASE_URL:"/api"'
# and replace the "/api" part.

# This is a common pattern for Vite apps. Vite injects `import.meta.env.VITE_API_BASE_URL`
# as a string literal in the bundle. You need to find what that string looks like after build.
# For example, it might become `o.env.VITE_API_BASE_URL="/default-api"`.
# You'll need to inspect your built files to find the exact string to replace.
# For simplicity, let's assume your build process outputs something like:
# 'VITE_API_BASE_URL_PLACEHOLDER'
# and we'll replace that.

# A more generic approach that often works is to replace a specific string within the JS files.
# For example, if your Vite app uses import.meta.env.VITE_API_BASE_URL,
# after build it might become `e.VITE_API_BASE_URL="/"` or similar.
# A common strategy is to make your Vite app fetch the config from a /config.js or /config.json endpoint
# that the entrypoint generates.

# Let's go with a more direct approach: create a separate config.js file on the fly.
# This avoids modifying the large bundled JS files and is often cleaner.

CONFIG_FILE="/usr/share/nginx/html/config.js"

echo "window.appConfig = {" > $CONFIG_FILE
echo "  VITE_API_BASE_URL: \"$VITE_API_BASE_URL\"" >> $CONFIG_FILE
echo "};" >> $CONFIG_FILE

# Now, ensure your index.html includes this config.js *before* your main app.
# Add a line like this to your index.html: <script src="/config.js"></script>

# Start Nginx
exec nginx -g "daemon off;"