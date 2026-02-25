FROM docker.io/python:3.14-slim

# hadolint ignore=DL3013
RUN pip install --no-cache-dir behave requests

COPY ./ /opt/app
WORKDIR /opt/app

CMD ["behave"]
