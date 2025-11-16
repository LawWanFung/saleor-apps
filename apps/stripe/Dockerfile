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
RUN pnpm run lint 
# Generate GraphQL types
WORKDIR /app/apps/stripe
RUN pnpm generate:app-graphql-types 
# RUN pnpm install
RUN pnpm run build 

# Check what's in the path
# RUN ls -la  

# Runtime stage
FROM node:22-alpine AS runner

# Set environment for the app
ENV NODE_ENV=production

# Set the working directory
WORKDIR /app

# 1. 複製核心 Next.js 運行環境所需的文件和 pnpm
# Next.js Server / Build output
COPY --from=builder /app/apps/stripe/.next ./.next
COPY --from=builder /app/apps/stripe/public ./public 

# 2. 複製依賴 (只需要生產環境的依賴)
# 透過 pnpm prune，只保留生產環境所需依賴
RUN npm install -g pnpm@10.6.3 # 在 runner 階段安裝 pnpm
COPY --from=builder /app/pnpm-lock.yaml ./pnpm-lock.yaml
COPY --from=builder /app/node_modules ./node_modules
# 複製 Apps 和 Packages (如果它們有額外的運行時依賴或邏輯)
COPY --from=builder /app/packages ./packages
COPY --from=builder /app/apps/stripe ./apps/stripe

# 3. (可選，但建議) 刪除開發依賴
RUN pnpm prune --prod

# Expose port
EXPOSE 3001

# Health check
HEALTHCHECK --interval=30s --timeout=10s --start-period=40s --retries=3 \
  CMD node -e "require('http').get('http://localhost:3001/api/health', (r) => {if (r.statusCode !== 200) throw new Error(r.statusCode)})"

# Start the app
CMD ["pnpm", "start", "-p", "3001"]