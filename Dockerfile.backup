# XSBH - Cross-platform BIM Fragment Viewer
# Lightweight Docker image for local deployment

FROM node:18-alpine AS builder

# Install system dependencies
RUN apk add --no-cache \
    python3 \
    py3-pip \
    build-base \
    python3-dev \
    linux-headers

# Set working directory
WORKDIR /app

# Copy package files
COPY frontend/package.json frontend/package-lock.json* ./frontend/
COPY backend/package.json backend/requirements.txt ./backend/

# Install frontend dependencies
WORKDIR /app/frontend
RUN npm ci

# Install backend dependencies
WORKDIR /app/backend
RUN pip install --no-cache-dir -r requirements.txt

# Copy source code
WORKDIR /app
COPY frontend/ ./frontend/
COPY backend/ ./backend/
COPY data/ ./data/

# Build frontend
WORKDIR /app/frontend
RUN npm run build

# ================================
# Production Image
# ================================
FROM python:3.11-alpine AS production

# Install runtime dependencies
RUN apk add --no-cache \
    nodejs \
    npm \
    nginx \
    supervisor \
    curl

# Create application structure
WORKDIR /app
RUN mkdir -p \
    /app/backend \
    /app/frontend/dist \
    /app/data/fragments \
    /app/data/ifc \
    /app/logs \
    /var/log/nginx \
    /var/lib/nginx/tmp \
    /run/nginx

# Copy built application
COPY --from=builder /app/backend /app/backend
COPY --from=builder /app/frontend/dist /app/frontend/dist
COPY --from=builder /app/data /app/data

# Copy configuration files
COPY docker/nginx.conf /etc/nginx/nginx.conf
COPY docker/supervisord.conf /etc/supervisor/conf.d/supervisord.conf
COPY scripts/docker-entrypoint.sh /usr/local/bin/

# Set permissions
RUN chmod +x /usr/local/bin/docker-entrypoint.sh && \
    chown -R nginx:nginx /var/log/nginx /var/lib/nginx /run/nginx && \
    chmod -R 755 /app

# Install Python dependencies in production
WORKDIR /app/backend
RUN pip install --no-cache-dir -r requirements.txt

# Set environment variables
ENV PYTHONPATH=/app/backend
ENV NODE_ENV=production
ENV FRAGMENTS_DATA_DIR=/app/data

# Expose port
EXPOSE 80

# Health check
HEALTHCHECK --interval=30s --timeout=10s --start-period=60s --retries=3 \
    CMD curl -f http://localhost:80/health || exit 1

# Volume for data persistence
VOLUME ["/app/data"]

# Start the application
ENTRYPOINT ["/usr/local/bin/docker-entrypoint.sh"]
CMD ["/usr/bin/supervisord", "-c", "/etc/supervisor/conf.d/supervisord.conf"]
