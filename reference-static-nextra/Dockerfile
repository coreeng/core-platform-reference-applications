FROM docker.io/node:26.5.0-alpine3.24 AS base
RUN npm install --global yarn@1.22.22

# Install dependencies only when needed
FROM base AS deps
RUN apk add --no-cache gcompat=1.1.0-r4
WORKDIR /app

# Install dependencies
COPY package.json yarn.lock* ./
RUN yarn --frozen-lockfile --ignore-scripts;

# Rebuild the source code only when needed
FROM base AS build
WORKDIR /app
COPY --from=deps /app/node_modules ./node_modules
COPY package.json yarn.lock* eslint.config.mjs next.config.ts postcss.config.mjs tsconfig.json jest.config.ts jest.setup.ts ./
COPY public ./public
COPY src ./src

# Build and test the app
RUN yarn run test && yarn run build

# Production image, copy all the files and run next
FROM docker.io/alpine:3.24.1 AS runner
WORKDIR /app

RUN apk add --no-cache libstdc++=15.2.0-r5

ENV NODE_ENV=production
ENV NEXT_TELEMETRY_DISABLED=1

RUN addgroup --system --gid 1001 nodejs \
 && adduser --system --uid 1001 nextjs

COPY --from=base /usr/local/bin/node /usr/local/bin/node
COPY --from=build /app/public ./public
COPY --from=build --chown=nextjs:nodejs /app/.next/standalone ./
COPY --from=build --chown=nextjs:nodejs /app/.next/static ./.next/static

USER nextjs

EXPOSE 3000
EXPOSE 8081

ENV PORT=3000
ENV HOSTNAME="0.0.0.0"

CMD ["node", "server.js"]
