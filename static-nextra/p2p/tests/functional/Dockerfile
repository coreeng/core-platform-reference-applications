FROM node:22.16.0-alpine3.22

WORKDIR /app

# Install dependencies
COPY package.json yarn.lock*  ./
RUN  yarn --frozen-lockfile;

# Copy only the needed files and folders individually
COPY tsconfig.json cucumber.json ./
COPY tests ./tests

CMD ["yarn", "test:cucumber"]
