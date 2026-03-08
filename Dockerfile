##########################################################################
# Multi-stage Dockerfile for decoryou application
# Build stage: Compile and prepare application
# Runtime stage: Minimal production image
##########################################################################

# ===========================
# STAGE 1: Builder
# ===========================
FROM node:18-alpine AS builder

LABEL maintainer="DevOps Team <devops@decoryou.com>"
LABEL description="Builder stage for decoryou application"

WORKDIR /build

# Install build dependencies
RUN apk add --no-cache \
    python3 \
    make \
    g++ \
    cairo-dev \
    jpeg-dev \
    pango-dev \
    giflib-dev

# Copy package files
COPY package*.json ./

# Install production dependencies
RUN npm ci --only=production && \
    npm cache clean --force

# Copy application source
COPY . .

# Build application (if needed)
RUN npm run build --if-present

# ===========================
# STAGE 2: Runtime
# ===========================
FROM node:18-alpine

LABEL maintainer="DevOps Team <devops@decoryou.com>"
LABEL description="Production image for decoryou application"
LABEL version="1.0.0"

# Set environment variables
ENV NODE_ENV=production \
    LOG_LEVEL=info \
    PORT=80

# Install runtime dependencies only
RUN apk add --no-cache \
    dumb-init \
    curl \
    ca-certificates && \
    addgroup -g 1001 appuser && \
    adduser -S -u 1001 -G appuser appuser

WORKDIR /app

# Copy built artifacts from builder stage
COPY --from=builder --chown=appuser:appuser /build/node_modules ./node_modules
COPY --from=builder --chown=appuser:appuser /build/package*.json ./
COPY --from=builder --chown=appuser:appuser /build/dist ./dist
COPY --from=builder --chown=appuser:appuser /build/public ./public
COPY --from=builder --chown=appuser:appuser /build/index.html ./

# Create required directories
RUN mkdir -p /app/logs && \
    chown -R appuser:appuser /app

# Switch to non-root user
USER appuser

# Health check
HEALTHCHECK --interval=30s --timeout=10s --start-period=5s --retries=3 \
    CMD curl -f http://localhost:${PORT}/health || exit 1

# Expose port
EXPOSE ${PORT}

# Use dumb-init to handle signals properly
ENTRYPOINT ["/sbin/dumb-init", "--"]

# Start application
CMD ["node", "dist/server.js"]

