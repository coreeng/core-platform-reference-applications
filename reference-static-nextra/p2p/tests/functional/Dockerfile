FROM docker.io/node:26.10.0-bookworm-slim AS node-runtime

FROM mcr.microsoft.com/playwright:v1.63.0-noble

COPY --from=node-runtime /usr/local/ /usr/local/
RUN npm install --global yarn@1.22.22 \
    && rm -rf /usr/bin/npm /usr/bin/npx /usr/lib/node_modules/npm \
        /usr/local/bin/npm /usr/local/bin/npx /usr/local/lib/node_modules/npm

WORKDIR /app

# Install dependencies
COPY package.json yarn.lock* ./
RUN yarn --frozen-lockfile --ignore-scripts;

# Copy only the needed files and folders individually
COPY tsconfig.json cucumber.json ./
COPY tests ./tests

CMD ["yarn", "test:cucumber"]
