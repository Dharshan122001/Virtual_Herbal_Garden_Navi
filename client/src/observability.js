import { datadogRum } from "@datadog/browser-rum";

const config = window.appConfig || {};

export function initBrowserMonitoring() {
  if (config.DATADOG_RUM_ENABLED !== "true") {
    return;
  }

  if (!config.DATADOG_RUM_APPLICATION_ID || !config.DATADOG_RUM_CLIENT_TOKEN) {
    console.warn("Datadog RUM is enabled but application ID or client token is missing.");
    return;
  }

  datadogRum.init({
    applicationId: config.DATADOG_RUM_APPLICATION_ID,
    clientToken: config.DATADOG_RUM_CLIENT_TOKEN,
    site: config.DATADOG_SITE || "datadoghq.com",
    service: config.DATADOG_RUM_SERVICE || "vhg-frontend",
    env: config.DATADOG_ENV || "aks",
    version: config.DATADOG_VERSION || "local",
    sessionSampleRate: Number(config.DATADOG_RUM_SESSION_SAMPLE_RATE || 100),
    sessionReplaySampleRate: Number(config.DATADOG_RUM_REPLAY_SAMPLE_RATE || 0),
    defaultPrivacyLevel: "mask-user-input",
    trackResources: true,
    trackLongTasks: true,
    trackUserInteractions: true,
    allowedTracingUrls: [/\/api\/plant/, /\/api\/auth/, /\/api\/ai/],
  });

  if (config.DATADOG_RUM_REPLAY_ENABLED === "true") {
    datadogRum.startSessionReplayRecording();
  }
}
