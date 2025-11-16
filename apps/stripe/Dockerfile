# Build stage
FROM node:22-alpine AS builder

WORKDIR /app

# Install pnpm
RUN npm install -g pnpm@10.6.3

# Copy workspace config
COPY pnpm-lock.yaml pnpm-workspace.yaml package.json turbo.json ./

# Copy all packages (shared libs)
COPY packages ./packages

# Copy stripe app
COPY apps/stripe ./apps/stripe

COPY .env.docker .env
COPY .env.docker ./apps/stripe/.env

# Install dependencies
RUN pnpm install --frozen-lockfile

# Generate GraphQL types
WORKDIR /app/apps/stripe

# Check what's in the path
# RUN ls -la

# Build the app - pass env vars to suppress ESLint warnings
RUN pnpm run lint
RUN pnpm run generate:app-graphql-types
RUN pnpm run build


# Runtime stage
FROM node:22-alpine AS runner

WORKDIR /app

# Install pnpm again for runtime
RUN npm install -g pnpm@10.6.3

# Copy necessary files from builder
COPY --from=builder /app/pnpm-lock.yaml /app/pnpm-workspace.yaml /app/package.json ./
COPY --from=builder /app/packages ./packages
COPY --from=builder /app/node_modules ./node_modules
COPY --from=builder /app/apps/stripe .

# Install production dependencies only
#RUN pnpm --filter=saleor-app-payment-stripe install --prod --frozen-lockfile

WORKDIR /app/apps/stripe
RUN npm build

# Expose port
EXPOSE 3000

# Health check
HEALTHCHECK --interval=30s --timeout=10s --start-period=40s --retries=3 \
  CMD node -e "require('http').get('http://localhost:3000/api/health', (r) => {if (r.statusCode !== 200) throw new Error(r.statusCode)})"

# Start the app
CMD ["pnpm", "start"]