FROM docker.io/node:26.5.0-bookworm-slim AS node-runtime

FROM mcr.microsoft.com/playwright:v1.61.1-noble

COPY --from=node-runtime /usr/local/ /usr/local/
RUN npm install --global yarn@1.22.22

WORKDIR /app

# Install dependencies
COPY package.json yarn.lock* ./
RUN yarn --frozen-lockfile --ignore-scripts;

# Copy only the needed files and folders individually
COPY tsconfig.json cucumber.json ./
COPY tests ./tests

CMD ["yarn", "test:cucumber"]
