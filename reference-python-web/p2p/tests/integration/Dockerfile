FROM docker.io/python:3.15.2-slim

RUN apt-get update \
 && apt-get upgrade -y \
 && apt-get clean \
 && rm -rf /var/lib/apt/lists/*

# hadolint ignore=DL3013
RUN pip install --no-cache-dir 'behave==1.3.3' 'requests==2.34.2' \
    && rm -rf /usr/local/bin/pip* /usr/local/lib/python3.15/site-packages/pip*

COPY ./ /opt/app
WORKDIR /opt/app

CMD ["behave"]
