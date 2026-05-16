import os
from opentelemetry import trace
from opentelemetry.sdk.trace import TracerProvider
from opentelemetry.sdk.trace.export import BatchSpanProcessor
from opentelemetry.exporter.otlp.proto.http.trace_exporter import OTLPSpanExporter
from opentelemetry.sdk.resources import Resource
from opentelemetry.instrumentation.fastapi import FastAPIInstrumentor
from opentelemetry.instrumentation.requests import RequestsInstrumentor
from opentelemetry.instrumentation.sqlalchemy import SQLAlchemyInstrumentor
from opentelemetry.propagate import set_global_textmap
from opentelemetry.propagators.b3 import B3FormatPropagator

def init_tracer(service_name: str):
    env = os.getenv("OTEL_ENV", "production")
    endpoint = os.getenv("OTEL_EXPORTER_OTLP_ENDPOINT", "http://datadog-otel-opentelemetry-collector.datadog.svc.cluster.local:4318")
    
    # Ensure correct OTLP HTTP path assignment
    if not endpoint.endswith("/v1/traces"):
        endpoint = f"{endpoint.rstrip('/')}/v1/traces"
        
    resource = Resource.create(attributes={
        "service.name": service_name,
        "deployment.environment": env,
        "version": os.getenv("DD_VERSION", "1.0.0")
    })
    
    provider = TracerProvider(resource=resource)
    processor = BatchSpanProcessor(OTLPSpanExporter(endpoint=endpoint))
    provider.add_span_processor(processor)
    trace.set_tracer_provider(provider)

def instrument_app(app, engine=None):
    # Bind runtime engine hooks cleanly
    FastAPIInstrumentor.instrument_app(app)
    RequestsInstrumentor().instrument()
    if engine:
        SQLAlchemyInstrumentor().instrument(engine=engine)