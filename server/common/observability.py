import os

from prometheus_client import start_http_server
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
    global _configured

    if _configured:
        return

    if os.getenv("OTEL_SDK_DISABLED", "false").lower() == "true":
        return

    resource = Resource.create(
        {
            "service.name": service_name,
            "service.version": os.getenv("OTEL_SERVICE_VERSION", "local"),
            "deployment.environment": os.getenv(
                "OTEL_DEPLOYMENT_ENVIRONMENT",
                "local",
            ),
        }
    )

    # ---------------- TRACING ---------------- #

    tracer_provider = TracerProvider(resource=resource)

    otlp_endpoint = os.getenv("OTEL_EXPORTER_OTLP_ENDPOINT")

    if otlp_endpoint:
        insecure = otlp_endpoint.startswith("http://")

        tracer_provider.add_span_processor(
            BatchSpanProcessor(
                OTLPSpanExporter(
                    endpoint=otlp_endpoint,
                    insecure=insecure,
                )
            )
        )

    trace.set_tracer_provider(tracer_provider)

    # ---------------- METRICS ---------------- #

    prometheus_port = int(os.getenv("OTEL_PROMETHEUS_PORT", "9464"))

    metric_reader = PrometheusMetricReader()

    meter_provider = MeterProvider(
        resource=resource,
        metric_readers=[metric_reader],
    )

    metrics.set_meter_provider(meter_provider)

    # THIS IS THE IMPORTANT FIX
    start_http_server(port=prometheus_port)

    # ---------------- INSTRUMENTATION ---------------- #

    RequestsInstrumentor().instrument()

    FastAPIInstrumentor.instrument_app(app)

    _configured = True