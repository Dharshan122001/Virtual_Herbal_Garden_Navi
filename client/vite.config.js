import { defineConfig } from 'vite'
import react from '@vitejs/plugin-react' // This might already be there
import tailwindcss from '@tailwindcss/vite' // Add this line

export default defineConfig({
  server: {
    port: 2001,
    host: true
  },
  plugins: [
    react(), // Keep existing plugins
    tailwindcss(), // Add the tailwindcss plugin
  ],
})