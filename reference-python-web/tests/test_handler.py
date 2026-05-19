from fastapi.testclient import TestClient

from app.handler import app
from app.internal import app as internal_app

client = TestClient(app)
internal_client = TestClient(internal_app)


def test_hello_default() -> None:
    response = client.get("/hello")
    assert response.status_code == 200
    assert response.text == "Hello world"


def test_hello_with_name() -> None:
    response = client.get("/hello?name=Alice")
    assert response.status_code == 200
    assert response.text == "Hello Alice"


def test_internal_status() -> None:
    response = internal_client.get("/internal/status")
    assert response.status_code == 200


def test_metrics_endpoint() -> None:
    response = internal_client.get("/metrics")
    assert response.status_code == 200
    assert "text/plain" in response.headers["content-type"]
