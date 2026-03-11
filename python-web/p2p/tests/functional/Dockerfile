FROM docker.io/python:3.14-slim

# hadolint ignore=DL3013
RUN pip install --no-cache-dir 'behave==1.3.3' 'requests==2.32.5'

COPY ./ /opt/app
WORKDIR /opt/app

CMD ["behave"]
