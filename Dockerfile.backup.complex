# Production Multi-stage Dockerfile
# Optimized for security, performance, and minimal attack surface

# ============================================
# Stage 1: Base Node.js for Frontend Build
# ============================================
FROM node:18-alpine AS base
WORKDIR /app
RUN apk add --no-cache git

# ============================================
# Stage 2: Frontend Dependencies
# ============================================
FROM base AS frontend-deps
COPY frontend/package*.json ./
RUN npm ci --only=production --no-audit --prefer-offline

# ============================================
# Stage 3: Frontend Build
# ============================================
FROM frontend-deps AS frontend-build
COPY frontend/ .
RUN npm run build

# ============================================
# Stage 4: Frontend Production
# ============================================
FROM nginx:alpine AS frontend-prod
# Install security updates
RUN apk update && apk upgrade && apk add --no-cache \
    curl \
    && rm -rf /var/cache/apk/*

# Create non-root user
RUN addgroup -g 1001 -S nginxgroup && \
    adduser -S nginxuser -u 1001 -G nginxgroup

COPY --from=frontend-build /app/dist /usr/share/nginx/html
COPY docker/nginx.prod.conf /etc/nginx/nginx.conf

# Set proper permissions
RUN chown -R nginxuser:nginxgroup /usr/share/nginx/html && \
    chown -R nginxuser:nginxgroup /var/cache/nginx && \
    chown -R nginxuser:nginxgroup /var/log/nginx && \
    chown -R nginxuser:nginxgroup /etc/nginx/conf.d

# Create PID directory
RUN mkdir -p /var/run/nginx && \
    chown -R nginxuser:nginxgroup /var/run/nginx

USER nginxuser

EXPOSE 8080
HEALTHCHECK --interval=30s --timeout=10s --start-period=5s --retries=3 \
    CMD curl -f http://localhost:8080/health || exit 1

CMD ["nginx", "-g", "daemon off;"]

# ============================================
# Stage 5: Python Base for Backend
# ============================================
FROM python:3.11-alpine AS python-base
WORKDIR /app

# Install system dependencies and security updates
RUN apk update && apk upgrade && apk add --no-cache \
    gcc \
    musl-dev \
    linux-headers \
    nodejs \
    npm \
    bash \
    curl \
    && rm -rf /var/cache/apk/*

# Create non-root user
RUN addgroup -g 1001 -S appgroup && \
    adduser -S appuser -u 1001 -G appgroup

# ============================================
# Stage 6: Backend Dependencies
# ============================================
FROM python-base AS backend-deps
COPY backend/requirements.txt .
COPY backend/package*.json ./

RUN pip install --no-cache-dir --upgrade pip && \
    pip install --no-cache-dir -r requirements.txt && \
    npm ci --only=production --no-audit

# ============================================
# Stage 7: Backend Production
# ============================================
FROM backend-deps AS backend-prod

# Copy application code
COPY backend/ .
COPY --chown=appuser:appgroup data/ ./data/

# Set proper permissions
RUN chown -R appuser:appgroup /app && \
    chmod +x /app/*.py

# Create required directories
RUN mkdir -p /app/logs /app/uploads && \
    chown -R appuser:appgroup /app/logs /app/uploads

USER appuser

EXPOSE 5000

# Health check
HEALTHCHECK --interval=30s --timeout=10s --start-period=40s --retries=3 \
    CMD python -c "import requests; requests.get('http://localhost:5000/health', timeout=5)" || exit 1

# Production entrypoint
CMD ["python", "app.py"]

# ============================================
# Security Labels
# ============================================
LABEL maintainer="XQG4_AXIS Team"
LABEL version="1.0.0"
LABEL description="XSBH Production BIM Fragment Viewer"
LABEL security.scan="enabled"
