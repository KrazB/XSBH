#!/bin/bash
set -e

# QGEN_IMPFRAG Production Health Check Script
# ===========================================
# 
# Comprehensive health checking for production deployments
# Run this script to verify system status and performance

echo "🏥 QGEN_IMPFRAG Health Check Report"
echo "=================================="
echo "Timestamp: $(date)"
echo ""

# Check Docker services
echo "📦 Docker Services Status:"
docker-compose ps --format "table {{.Name}}\t{{.State}}\t{{.Status}}"
echo ""

# Check backend health
echo "🔧 Backend Health:"
BACKEND_HEALTH=$(curl -s -o /dev/null -w "%{http_code}" http://localhost:8000/health || echo "000")
if [ "$BACKEND_HEALTH" = "200" ]; then
    echo "✅ Backend API: Healthy"
    curl -s http://localhost:8000/health | jq '.'
else
    echo "❌ Backend API: Unhealthy (HTTP $BACKEND_HEALTH)"
fi
echo ""

# Check frontend availability
echo "🎨 Frontend Status:"
FRONTEND_STATUS=$(curl -s -o /dev/null -w "%{http_code}" http://localhost:80/ || echo "000")
if [ "$FRONTEND_STATUS" = "200" ]; then
    echo "✅ Frontend: Available"
else
    echo "❌ Frontend: Unavailable (HTTP $FRONTEND_STATUS)"
fi
echo ""

# Check disk space
echo "💾 Disk Space Usage:"
df -h | grep -E "(Filesystem|/data|/$)"
echo ""

# Check data directories
echo "📁 Data Directory Status:"
if [ -d "/data/XVUE/XQG4_AXIS/QGEN_IMPFRAG/data/ifc" ]; then
    IFC_COUNT=$(find /data/XVUE/XQG4_AXIS/QGEN_IMPFRAG/data/ifc -name "*.ifc" | wc -l)
    echo "📋 IFC Files: $IFC_COUNT"
else
    echo "❌ IFC directory not found"
fi

if [ -d "/data/XVUE/XQG4_AXIS/QGEN_IMPFRAG/data/fragments" ]; then
    FRAG_COUNT=$(find /data/XVUE/XQG4_AXIS/QGEN_IMPFRAG/data/fragments -name "*.frag" | wc -l)
    echo "🧩 Fragment Files: $FRAG_COUNT"
else
    echo "❌ Fragments directory not found"
fi
echo ""

# Check recent logs for errors
echo "📋 Recent Log Errors:"
if [ -d "backend/logs" ]; then
    find backend/logs -name "*.log" -mtime -1 -exec grep -l "ERROR\|CRITICAL" {} \; | head -5
    echo "Recent error count: $(find backend/logs -name "*.log" -mtime -1 -exec grep -c "ERROR\|CRITICAL" {} \; | awk '{sum += $1} END {print sum}')"
else
    echo "No recent log errors found"
fi
echo ""

# Memory usage
echo "🧠 Memory Usage:"
free -h
echo ""

# Network connectivity
echo "🌐 Network Connectivity:"
if docker network inspect qgen-network >/dev/null 2>&1; then
    echo "✅ Docker network: qgen-network exists"
else
    echo "❌ Docker network: qgen-network missing"
fi

# Port availability
echo "🔌 Port Status:"
ss -tlnp | grep -E "(8000|80|3000)" || echo "No services listening on expected ports"

echo ""
echo "🎯 Health Check Complete!"
echo "=================================="
