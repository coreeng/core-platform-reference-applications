import time

import requests
from behave import given, then, when


@given("a rest service")
def step_a_rest_service(context):
    context.session = requests.Session()
    context.response = None


@when("I call the hello world endpoint")
def step_call_hello_world(context):
    url = f"{context.base_uri}/hello"
    context.response = context.session.get(url, timeout=10)


@when("I call the ingress hello world endpoint and wait for it to be ready")
def step_call_ingress_hello_world(context):
    url = f"{context.ingress_base_uri}/hello"
    last_error = None
    for attempt in range(8):
        try:
            context.response = context.session.get(url, timeout=10)
            return
        except requests.RequestException as e:
            last_error = e
            print(f"GET {url} failed (attempt {attempt + 1}/8), retrying in 10s: {e}")
            time.sleep(10)
    msg = f"All attempts to reach {url} failed"
    raise AssertionError(msg) from last_error


@then("an ok response is returned")
def step_ok_response(context):
    assert context.response is not None, "No response received"
    assert context.response.ok, (
        f"Expected a successful response but got {context.response.status_code}"
    )
