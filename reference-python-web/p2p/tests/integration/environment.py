import os


def before_all(context):
    context.base_uri = os.environ.get("SERVICE_ENDPOINT", "http://service:8080")
    context.ingress_base_uri = os.environ.get("INGRESS_ENDPOINT", "")
