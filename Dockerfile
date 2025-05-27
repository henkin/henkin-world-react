# Dockerfile
# Stage 1: Build the application
FROM node:20-alpine AS builder

WORKDIR /app

# Copy package.json and package-lock.json
COPY package.json package-lock.json* ./

# Install dependencies
RUN npm install --frozen-lockfile

# Copy the rest of the application code
COPY . .

# Set NEXT_TELEMETRY_DISABLED to 1 to disable telemetry during build
ENV NEXT_TELEMETRY_DISABLED 1

# Build the application
RUN npm run build

# Stage 2: Production image
FROM node:20-alpine AS runner

WORKDIR /app

# Copy package.json and package-lock.json
COPY package.json package-lock.json* ./

# Install only production dependencies
RUN npm install --frozen-lockfile --omit=dev

# Copy built assets from the builder stage
COPY --from=builder /app/.next ./.next
COPY --from=builder /app/public ./public
COPY --from=builder /app/next.config.js ./next.config.js
COPY --from=builder /app/instrumentation.ts ./instrumentation.ts
COPY --from=builder /app/middleware.ts ./middleware.ts
COPY --from=builder /app/next-i18next.config.js ./next-i18next.config.js
COPY --from=builder /app/locales ./locales
COPY --from=builder /app/prisma ./prisma

# Set NEXT_TELEMETRY_DISABLED to 1 to disable telemetry
ENV NEXT_TELEMETRY_DISABLED 1
ENV NODE_ENV production

# Expose the port the app runs on
EXPOSE 4002

# Run migrations and then start the application
CMD ["sh", "-c", "npm run migrate:deploy && npm run start"] 