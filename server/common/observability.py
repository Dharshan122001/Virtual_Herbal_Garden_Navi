import os
import traceback

from prometheus_client import start_http_server

from opentelemetry import trace
from opentelemetry.exporter.otlp.proto.grpc.trace_exporter import OTLPSpanExporter

from opentelemetry.instrumentation.fastapi import FastAPIInstrumentor
from opentelemetry.instrumentation.requests import RequestsInstrumentor

from opentelemetry.sdk.resources import Resource
from opentelemetry.sdk.trace import TracerProvider
from opentelemetry.sdk.trace.export import BatchSpanProcessor

_configured = False


def configure_observability(app, service_name: str) -> None:
    global _configured

    if _configured:
        return

    try:
        if os.getenv("OTEL_SDK_DISABLED", "false").lower() == "true":
            print("OTEL DISABLED")
            return

        resource = Resource.create(
            {
                "service.name": service_name,
                "service.version": os.getenv(
                    "OTEL_SERVICE_VERSION",
                    "local",
                ),
                "deployment.environment": os.getenv(
                    "OTEL_DEPLOYMENT_ENVIRONMENT",
                    "local",
                ),
            }
        )

        # =========================
        # TRACING
        # =========================

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

        # =========================
        # PROMETHEUS
        # =========================

        metrics_port = int(
            os.getenv("OTEL_PROMETHEUS_PORT", "9464")
        )

        print(f"STARTING PROMETHEUS SERVER ON PORT {metrics_port}")

        start_http_server(addr="0.0.0.0", port=metrics_port)

        print("PROMETHEUS SERVER STARTED")

        # =========================
        # INSTRUMENTATION
        # =========================

        FastAPIInstrumentor.instrument_app(app)

        RequestsInstrumentor().instrument()

        _configured = True

        print("OBSERVABILITY CONFIGURED")

    except Exception as e:
        print("OBSERVABILITY ERROR")
        print(str(e))
        traceback.print_exc()