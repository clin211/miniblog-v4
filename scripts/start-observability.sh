#!/bin/bash

# MiniBlog v4 可观测性平台启动脚本

set -e

echo "🚀 启动 MiniBlog v4 可观测性平台..."

# 检查 Docker 是否运行
if ! docker info > /dev/null 2>&1; then
    echo "❌ Docker 未运行，请先启动 Docker"
    exit 1
fi

# 创建必要的目录
echo "📁 创建数据目录..."
mkdir -p data/{tempo,victoria-metrics,grafana,vector}
mkdir -p logs

# 设置权限
chmod -R 755 data/
chmod -R 755 logs/

# 启动可观测性服务
echo "🔧 启动可观测性服务..."
docker compose -f docker-compose.observability.yml up -d

# 等待服务启动
echo "⏳ 等待服务启动..."
sleep 10

# 检查服务状态
echo "📊 检查服务状态..."
echo ""
echo "📍 服务访问地址："
echo "   • Grafana:        http://localhost:3000 (admin/admin123)"
echo "   • VictoriaMetrics: http://localhost:8428"
echo "   • Tempo:         http://localhost:3200"
echo "   • OTEL Collector: http://localhost:13133/healthz"
echo ""

# 验证服务健康状态
echo "🏥 检查服务健康状态..."
services=("grafana:3000" "victoria-metrics:8428" "tempo:3200" "miniblog-otel-collector:13133")

for service in "${services[@]}"; do
    name=$(echo $service | cut -d: -f1)
    port=$(echo $service | cut -d: -f2)

    if curl -s http://localhost:$port/healthz > /dev/null 2>&1 || \
       curl -s http://localhost:$3000/api/health > /dev/null 2>&1 || \
       curl -s http://localhost:$8428/health > /dev/null 2>&1 || \
       curl -s http://localhost:$3200/ready > /dev/null 2>&1; then
        echo "   ✅ $name: 健康"
    else
        echo "   ❌ $name: 未响应"
    fi
done

echo ""
echo "✨ 可观测性平台启动完成！"
echo ""
echo "💡 使用提示："
echo "   1. 启动应用: make build BINS=blog-apiserver && ./_output/platforms/$(go env GOOS)/$(go env GOARCH)/blog-apiserver --config configs/blog-apiserver.yaml"
echo "   2. 查看指标: curl http://localhost:5556/metrics"
echo "   3. 查看日志: tail -f logs/blog-apiserver.log"
echo "   4. 停止服务: docker compose -f docker-compose.observability.yml down"