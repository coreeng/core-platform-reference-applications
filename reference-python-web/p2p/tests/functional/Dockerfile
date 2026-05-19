FROM docker.io/python:3.14.4-slim

# hadolint ignore=DL3013
RUN pip install --no-cache-dir 'behave==1.3.3' 'requests==2.34.0'

COPY ./ /opt/app
WORKDIR /opt/app

CMD ["behave"]
