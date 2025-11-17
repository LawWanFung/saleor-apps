# 0. Pruner stage
FROM node:22-alpine AS pruner
WORKDIR /app

RUN npm install -g pnpm@10.6.3 turbo@2.6.1
COPY pnpm-lock.yaml pnpm-workspace.yaml package.json turbo.json ./
COPY packages ./packages
COPY apps/stripe ./apps/stripe

RUN pnpm dlx turbo@2.6.1 prune saleor-app-payment-stripe --docker --out-dir out

RUN ls -la
RUN ls -la ./out
RUN ls -la ./out/full

# 1. Build stage
FROM node:22-alpine AS builder

WORKDIR /app

# Install pnpm
RUN npm install -g pnpm@10.6.3

# 用 pruner 嘅 output 做 context
COPY --from=pruner /app/out/pnpm-lock.yaml pnpm-lock.yaml
COPY --from=pruner /app/out/pnpm-workspace.yaml pnpm-workspace.yaml
COPY --from=pruner /app/out/full/package.json package.json
COPY --from=pruner /app/out/full/apps ./apps
COPY --from=pruner /app/out/full/packages ./packages
COPY --from=pruner /app/out/full/turbo.json turbo.json 
 # 如果 lint/build 會用到

# # Copy workspace config
# COPY pnpm-lock.yaml pnpm-workspace.yaml package.json turbo.json ./

# # Copy all packages (shared libs)
# COPY packages ./packages

# # Copy stripe app
# COPY apps/stripe ./apps/stripe

COPY .env.docker .env
COPY .env.docker ./apps/stripe/.env


# Install dependencies
RUN pnpm install --filter saleor-app-payment-stripe... --filter @saleor/* --frozen-lockfile
RUN pnpm --filter saleor-app-payment-stripe... run lint 
# Generate GraphQL types
WORKDIR /app/apps/stripe

RUN ls -la
RUN ls /app/apps/
RUN ls /app/apps/stripe/


RUN pnpm --filter saleor-app-payment-stripe... generate:app-graphql-types 
# RUN pnpm install
RUN pnpm --filter saleor-app-payment-stripe... run build 

# Check what's in the path
# RUN ls -la  

# Runtime stage
FROM node:22-alpine AS runner

# # Set environment for the app
# ENV NODE_ENV=production

# # Set the working directory
# WORKDIR /app

# # 1. 複製核心 Next.js 運行環境所需的文件和 pnpm
# # Next.js Server / Build output
# COPY --from=builder /app/apps/stripe/.next ./.next
# COPY --from=builder /app/apps/stripe/public ./public 

# # 2. 複製依賴 (只需要生產環境的依賴)
# # 透過 pnpm prune，只保留生產環境所需依賴
# RUN npm install -g pnpm@10.6.3 # 在 runner 階段安裝 pnpm
# COPY --from=builder /app/pnpm-lock.yaml ./pnpm-lock.yaml
# COPY --from=builder /app/package.json ./package.json
# COPY --from=builder /app/node_modules ./node_modules
# # 複製 Apps 和 Packages (如果它們有額外的運行時依賴或邏輯)
# COPY --from=builder /app/packages ./packages
# COPY --from=builder /app/apps/stripe ./apps/stripe

# # 3. (可選，但建議) 刪除開發依賴
# RUN pnpm prune --prod

# ===============================================
# 🚀 Standalone 最終優化 (Monorepo-Safe Launch)
# 將工作目錄設定為應用程式根目錄，確保 server.js 能找到所有相對路徑的構建資源
# ===============================================

# 🎯 設定工作目錄到應用程式目錄 (與 build 時相同)
WORKDIR /app

# 1. 複製 Standalone 模式輸出的所有內容 (包含 server.js 和依賴)
# 🎯 關鍵: 複製到 /app/apps/stripe/
COPY --from=builder /app/apps/stripe/.next/standalone ./
COPY --from=builder /app/apps/stripe/.next/static ./
# 2. 複製 public 檔案 (靜態資源)
# 路徑結構：/app/apps/stripe/public -> 容器的 /app/apps/stripe/public
COPY --from=builder /app/apps/stripe/public ./apps/stripe/public 

RUN ls -la ./apps
RUN ls -la ./apps/stripe
RUN ls -la ./apps/stripe/.next

RUN find . -type d -name "static"

# Set environment
ENV NODE_ENV=production
ENV PORT=3001
ENV HOSTNAME=0.0.0.0

EXPOSE 3001

# Health check
HEALTHCHECK --interval=30s --timeout=10s --start-period=40s --retries=3 \
  CMD node -e "require('http').get('http://localhost:3001/', (r) => {if (r.statusCode !== 200) throw new Error(r.statusCode)})"

# Start the app
# CMD ["pnpm", "start", "-p", "3001"]
CMD ["node", "apps/stripe/server.js", "-p", "3001"]