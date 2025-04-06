# Use a specific node version
FROM node:18-alpine AS deps
WORKDIR /app

# Install dependencies only when needed
COPY package.json package-lock.json* pnpm-lock.yaml* ./
RUN \
  if [ -f pnpm-lock.yaml ]; then \
    npm install -g pnpm && pnpm install; \
  elif [ -f package-lock.json ]; then \
    npm install; \
  else \
    echo "No lockfile found!" && exit 1; \
  fi

# Rebuild the source code
FROM node:18-alpine AS builder
WORKDIR /app
COPY --from=deps /app/node_modules ./node_modules
COPY . .

# Build Next.js app
RUN npm run build

# Final production image
FROM node:18-alpine AS runner
WORKDIR /app

ENV NODE_ENV production

# Copy only necessary files
COPY --from=builder /app/public ./public
COPY --from=builder /app/.next ./.next
COPY --from=builder /app/node_modules ./node_modules
COPY --from=builder /app/package.json ./package.json

# Expose the port and start the app
EXPOSE 3000
CMD ["npm", "start"]
