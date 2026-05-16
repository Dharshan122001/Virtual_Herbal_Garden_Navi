import { StrictMode } from "react";
import { createRoot } from "react-dom/client";
import { BrowserRouter } from "react-router-dom";
import { datadogRum } from '@datadog/browser-rum'; // Using the official package import
import "./index.css";
import App from "./App.jsx";

function initDatadogRum() {
  // Pull values dynamically from the Nginx /config.js injection
  const config = window.appConfig || {};
  
  const applicationId = config.VITE_DATADOG_RUM_APP_ID || import.meta.env.VITE_DATADOG_RUM_APP_ID;
  const clientToken = config.VITE_DATADOG_RUM_CLIENT_TOKEN || import.meta.env.VITE_DATADOG_RUM_CLIENT_TOKEN;
  const site = config.VITE_DATADOG_SITE || import.meta.env.VITE_DATADOG_SITE || "us5.datadoghq.com";
  const env = config.VITE_OTEL_ENV || import.meta.env.VITE_OTEL_ENV || "production";

  if (!applicationId || !clientToken) {
    console.warn("Datadog RUM configuration missing. Skipping initialization.");
    return;
  }

  datadogRum.init({
    applicationId: applicationId,
    clientToken: clientToken,
    site: site,
    service: "vhg-frontend",
    env: env,
    version: "1.0.0",
    sessionSampleRate: 100,
    sessionReplaySampleRate: 20, // Capture 20% of sessions for visual video playback replays
    trackResources: true,
    trackUserInteractions: true,
    trackLongTasks: true,
    defaultPrivacyLevel: 'mask-user-input',

    // CRITICAL FOR PRODUCTION DISTRIBUTED TRACING:
    // This connects browser network calls directly to backends
    allowedTracingUrls: [
      { match: config.VITE_PLANT_API_URL || "/api/plant", types: ['tracecontext', 'datadog'] },
      { match: config.VITE_AUTH_API_URL || "/api/auth", types: ['tracecontext', 'datadog'] },
      { match: config.VITE_AI_API_URL || "/api/ai", types: ['tracecontext', 'datadog'] }
    ]
  });
}

// Fire initialization before mounting the application
initDatadogRum();

createRoot(document.getElementById("root")).render(
  <StrictMode>
    <BrowserRouter>
      <App />
    </BrowserRouter>
  </StrictMode>
);