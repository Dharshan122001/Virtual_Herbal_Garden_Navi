import os

from opentelemetry import metrics, trace
from opentelemetry.exporter.otlp.proto.grpc.trace_exporter import (
    OTLPSpanExporter,
)
from opentelemetry.exporter.prometheus import PrometheusMetricReader
from opentelemetry.instrumentation.fastapi import FastAPIInstrumentor
from opentelemetry.instrumentation.requests import RequestsInstrumentor
from opentelemetry.instrumentation.sqlalchemy import (
    SQLAlchemyInstrumentor,
)
from opentelemetry.sdk.metrics import MeterProvider
from opentelemetry.sdk.resources import Resource
from opentelemetry.sdk.trace import TracerProvider
from opentelemetry.sdk.trace.export import BatchSpanProcessor

_configured = False


def configure_observability(app, service_name: str) -> None:
    global _configured

    if os.getenv("OTEL_SDK_DISABLED", "false").lower() == "true":
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

    if not _configured:

        # =========================
        # TRACES
        # =========================

        tracer_provider = TracerProvider(resource=resource)

        otlp_endpoint = os.getenv(
            "OTEL_EXPORTER_OTLP_ENDPOINT",
            "otel-collector.monitoring.svc.cluster.local:4317",
        )

        tracer_provider.add_span_processor(
            BatchSpanProcessor(
                OTLPSpanExporter(
                    endpoint=otlp_endpoint,
                    insecure=True,
                )
            )
        )

        trace.set_tracer_provider(tracer_provider)

        # =========================
        # METRICS
        # =========================

        prometheus_reader = PrometheusMetricReader()

        meter_provider = MeterProvider(
            resource=resource,
            metric_readers=[prometheus_reader],
        )

        metrics.set_meter_provider(meter_provider)

        # =========================
        # INSTRUMENTATION
        # =========================

        RequestsInstrumentor().instrument()

        try:
            from common.database import engine

            SQLAlchemyInstrumentor().instrument(
                engine=engine.sync_engine
                if hasattr(engine, "sync_engine")
                else engine
            )
        except Exception as e:
            print("SQLAlchemy instrumentation skipped:", e)

        _configured = True

    FastAPIInstrumentor.instrument_app(app)