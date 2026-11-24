FROM docker.io/node:26.13.1-trixie-slim@sha256:e6bedef217677b276c591795e169840edd9096dbf13f29df8ef8d1856b8820bc AS node-runtime

FROM mcr.microsoft.com/playwright:v1.65.1-resolute@sha256:dcf385f7a31aa1cbb0a7a0c97a539142bf70480b661f89f26a774ec1fe2edd1d AS browser

COPY --from=node-runtime /usr/local/ /usr/local/
RUN npm install --global npm@12.2.3 \
    && npm install --global yarn@1.22.22 \
    && rm -rf /usr/bin/npm /usr/bin/npx /usr/lib/node_modules/npm \
        /usr/local/bin/npm /usr/local/bin/npx /usr/local/lib/node_modules/npm \
    && apt-get update \
    && apt-get upgrade -y \
    && apt-get purge -y gstreamer1.0-plugins-bad libgstreamer-plugins-bad1.0-0 \
    # The runner starts Cucumber directly. Pebble is an unmanaged binary in the base image.
    && rm -f /usr/bin/pebble \
    && rm -rf /var/lib/apt/lists/*

WORKDIR /app

FROM browser AS suite

# Install dependencies
COPY package.json yarn.lock ./
RUN yarn --frozen-lockfile --ignore-scripts

# Copy only the needed files and folders individually
COPY tsconfig.json cucumber.json ./
COPY tests ./tests
RUN yarn tsc --noEmit \
    && rm -rf node_modules/typescript node_modules/@typescript/typescript-* node_modules/.bin/tsc

FROM browser
COPY --from=suite /app/ /app/
CMD ["yarn", "test:cucumber"]
