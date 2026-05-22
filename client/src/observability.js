const config = window.appConfig || {};

export function initBrowserMonitoring() {
  // Browser-side monitoring is currently disabled in favor of
  // Prometheus + Grafana backend observability.
  if (config.OTEL_BROWSER_MONITORING_ENABLED !== "true") {
    return;
  }

  // If frontend browser instrumentation is added later, implement
  // the OpenTelemetry JS browser SDK here.
}
