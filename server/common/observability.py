import os

from opentelemetry import metrics, trace
from opentelemetry.exporter.otlp.proto.grpc.trace_exporter import OTLPSpanExporter
from opentelemetry.exporter.prometheus import PrometheusMetricReader
from opentelemetry.instrumentation.fastapi import FastAPIInstrumentor
from opentelemetry.instrumentation.requests import RequestsInstrumentor
from opentelemetry.sdk.metrics import MeterProvider
from opentelemetry.sdk.resources import Resource
from opentelemetry.sdk.trace import TracerProvider
from opentelemetry.sdk.trace.export import BatchSpanProcessor

_configured = False


def configure_observability(app, service_name: str) -> None:
    """Configure OpenTelemetry tracing and Prometheus metrics for a FastAPI service."""
    global _configured

    if os.getenv("OTEL_SDK_DISABLED", "false").lower() == "true":
        return

    resource = Resource.create(
        {
            "service.name": service_name,
            "service.version": os.getenv("OTEL_SERVICE_VERSION", "local"),
            "deployment.environment": os.getenv("OTEL_DEPLOYMENT_ENVIRONMENT", "local"),
        }
    )

    if not _configured:
        tracer_provider = TracerProvider(resource=resource)
        otlp_endpoint = os.getenv("OTEL_EXPORTER_OTLP_ENDPOINT")
        if otlp_endpoint:
            insecure = otlp_endpoint.startswith("http://")
            tracer_provider.add_span_processor(
                BatchSpanProcessor(
                    OTLPSpanExporter(endpoint=otlp_endpoint, insecure=insecure)
                )
            )
        trace.set_tracer_provider(tracer_provider)

        prometheus_port = int(os.getenv("OTEL_PROMETHEUS_PORT", "9464"))
        metric_reader = PrometheusMetricReader(port=prometheus_port, endpoint="/metrics")
        metrics.set_meter_provider(MeterProvider(resource=resource, metric_readers=[metric_reader]))

        RequestsInstrumentor().instrument()
        _configured = True

    FastAPIInstrumentor.instrument_app(app)
