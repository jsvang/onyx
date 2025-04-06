# Use the Node.js official image from the Docker registry
FROM node:18-alpine AS deps
WORKDIR /app

# Copy package.json and lock files
COPY package.json package-lock.json* pnpm-lock.yaml* ./

# Install dependencies
RUN \
  if [ -f pnpm-lock.yaml ]; then \
    npm install -g pnpm && pnpm install; \
  elif [ -f package-lock.json ]; then \
    npm install; \
  else \
    echo "No lockfile found!" && exit 1; \
  fi

# Copy source code and build
FROM node:18-alpine AS builder
WORKDIR /app

# Copy dependencies from previous step
COPY --from=deps /app/node_modules ./node_modules

# Copy the rest of the project
COPY . .

# Build the app
RUN npm run build

# Production image
FROM node:18-alpine AS runner
WORKDIR /app

# Set the environment to production
ENV NODE_ENV production

# Copy built files from the builder stage
COPY --from=builder /app/public ./public
COPY --from=builder /app/.next ./.next
COPY --from=builder /app/node_modules ./node_modules
COPY --from=builder /app/package.json ./package.json

# Expose the app on port 3000
EXPOSE 3000

# Run the Next.js app
CMD ["npm", "start"]
