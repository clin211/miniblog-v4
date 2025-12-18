#!/bin/bash

# MiniBlog v4 完整启动脚本

set -e

echo "🚀 启动 MiniBlog v4 完整环境..."

# 检查 Docker 是否运行
if ! docker info > /dev/null 2>&1; then
    echo "❌ Docker 未运行，请先启动 Docker"
    exit 1
fi

# 创建必要的目录
echo "📁 创建数据目录..."
mkdir -p data/{pgdata,redisdata,tempo,victoria-metrics,grafana,vector}
mkdir -p logs

# 设置权限
chmod -R 755 data/
chmod -R 755 logs/

# 启动基础服务（PostgreSQL, Redis）
echo "🗄️ 启动基础服务..."
docker compose -f docker-compose.env.yml up -d

# 等待基础服务启动
echo "⏳ 等待基础服务启动..."
sleep 5

# 启动可观测性服务
echo "📊 启动可观测性服务..."
docker compose -f docker-compose.observability.yml up -d

# 等待所有服务启动
echo "⏳ 等待所有服务启动..."
sleep 10

# 检查服务状态
echo ""
echo "📍 服务访问地址："
echo ""
echo "🔧 基础服务："
echo "   • PostgreSQL: localhost:54321"
echo "   • Redis:      localhost:56379"
echo ""
echo "📊 可观测性服务："
echo "   • Grafana:        http://localhost:3000 (admin/admin123)"
echo "   • VictoriaMetrics: http://localhost:8428"
echo "   • Tempo:         http://localhost:3200"
echo "   • OTEL Collector: http://localhost:13133/healthz"
echo ""

# 验证服务健康状态
echo "🏥 检查服务健康状态..."
services=("postgres:54321" "redis:56379" "victoria-metrics:8428")

for service in "${services[@]}"; do
    name=$(echo $service | cut -d: -f1)
    port=$(echo $service | cut -d: -f2)

    if [ "$name" = "postgres" ]; then
        if docker exec miniblog-postgres pg_isready -U postgres -d blog-v4 > /dev/null 2>&1; then
            echo "   ✅ PostgreSQL: 健康"
        else
            echo "   ❌ PostgreSQL: 未响应"
        fi
    elif [ "$name" = "redis" ]; then
        if docker exec miniblog-redis redis-cli -a Q6jAu8trwDEcJN7V ping > /dev/null 2>&1; then
            echo "   ✅ Redis: 健康"
        else
            echo "   ❌ Redis: 未响应"
        fi
    elif curl -s http://localhost:$8428/health > /dev/null 2>&1; then
        echo "   ✅ VictoriaMetrics: 健康"
    else
        echo "   ❌ VictoriaMetrics: 未响应"
    fi
done

echo ""
echo "✨ MiniBlog v4 环境启动完成！"
echo ""
echo "💡 下一步操作："
echo "   1. 构建应用: make build BINS=blog-apiserver"
echo "   2. 启动应用: ./_output/platforms/\$(go env GOOS)/\$(go env GOARCH)/blog-apiserver --config configs/blog-apiserver.yaml"
echo "   3. 查看指标: curl http://localhost:5556/metrics"
echo "   4. 查看日志: tail -f logs/blog-apiserver.log"
echo ""
echo "🛑 停止服务:"
echo "   • 停止所有服务: ./scripts/stop-all.sh"
echo "   • 只停止基础服务: docker compose -f docker-compose.env.yml down"
echo "   • 只停止可观测性服务: make observability.stop"