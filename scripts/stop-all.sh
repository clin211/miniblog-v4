#!/bin/bash

# MiniBlog v4 停止所有服务

set -e

echo "🛑 停止 MiniBlog v4 所有服务..."

# 停止可观测性服务
echo "📊 停止可观测性服务..."
docker compose -f docker-compose.observability.yml down

# 停止基础服务
echo "🗄️ 停止基础服务..."
docker compose -f docker-compose.env.yml down

# 清理未使用的网络（可选）
echo "🧹 清理未使用的网络..."
docker network prune -f

echo "✅ 所有服务已停止！"

# 显示已停止的服务
echo ""
echo "已停止的服务："
echo "   • PostgreSQL"
echo "   • Redis"
echo "   • Grafana Tempo"
echo "   • VictoriaMetrics"
echo "   • Grafana"
echo "   • OpenTelemetry Collector"
echo "   • Vector"