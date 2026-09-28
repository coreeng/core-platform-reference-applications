FROM docker.io/python:3.14.7-slim

# hadolint ignore=DL3013
RUN pip install --no-cache-dir 'behave==1.3.3' 'requests==2.34.2' \
    && rm -rf /usr/local/bin/pip* /usr/local/lib/python3.14/site-packages/pip*

COPY ./ /opt/app
WORKDIR /opt/app

CMD ["behave"]
