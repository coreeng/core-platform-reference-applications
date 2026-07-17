FROM docker.io/node:26.5.0-bookworm-slim AS node-runtime

FROM mcr.microsoft.com/playwright:v1.61.1-noble

COPY --from=node-runtime /usr/local/ /usr/local/
ENV YARN_NODE_LINKER=node-modules \
    YARN_ENABLE_GLOBAL_CACHE=true \
    YARN_ENABLE_SCRIPTS=true
RUN npm install --global @yarnpkg/cli-dist@4.17.1

WORKDIR /app

# Install dependencies
COPY package.json yarn.lock* ./
RUN yarn install --immutable --mode=skip-build \
    && yarn cache clean --all

# Copy only the needed files and folders individually
COPY tsconfig.json cucumber.json ./
COPY tests ./tests

CMD ["yarn", "test:cucumber"]
