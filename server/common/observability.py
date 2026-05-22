import os
import logging

from prometheus_client import start_http_server

from opentelemetry import trace

from opentelemetry.exporter.otlp.proto.grpc.trace_exporter import (
    OTLPSpanExporter,
)

from opentelemetry.instrumentation.fastapi import (
    FastAPIInstrumentor,
)

from opentelemetry.instrumentation.requests import (
    RequestsInstrumentor,
)

from opentelemetry.sdk.resources import Resource

from opentelemetry.sdk.trace import TracerProvider

from opentelemetry.sdk.trace.export import (
    BatchSpanProcessor,
)

_configured = False

logger = logging.getLogger(__name__)


def configure_observability(app, service_name: str) -> None:
    global _configured

    if _configured:
        return

    if os.getenv("OTEL_SDK_DISABLED", "false").lower() == "true":
        logger.warning("OTEL SDK disabled")
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

    tracer_provider = TracerProvider(
        resource=resource
    )

    otlp_endpoint = os.getenv(
        "OTEL_EXPORTER_OTLP_ENDPOINT"
    )

    if otlp_endpoint:
        insecure = otlp_endpoint.startswith(
            "http://"
        )

        tracer_provider.add_span_processor(
            BatchSpanProcessor(
                OTLPSpanExporter(
                    endpoint=otlp_endpoint,
                    insecure=insecure,
                )
            )
        )

    trace.set_tracer_provider(
        tracer_provider
    )

    # =========================
    # PROMETHEUS METRICS
    # =========================

    try:
        metrics_port = int(
            os.getenv(
                "OTEL_PROMETHEUS_PORT",
                "9464",
            )
        )

        logger.warning(
            f"Starting Prometheus metrics server on {metrics_port}"
        )

        start_http_server(
            addr="0.0.0.0",
            port=metrics_port,
        )

        logger.warning(
            "Prometheus metrics server started successfully"
        )

    except Exception as e:
        logger.exception(
            f"Failed to start metrics server: {e}"
        )

    # =========================
    # INSTRUMENTATION
    # =========================

    FastAPIInstrumentor.instrument_app(
        app
    )

    RequestsInstrumentor().instrument()

    _configured = True