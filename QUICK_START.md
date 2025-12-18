# MiniBlog v4 快速开始

## 🚀 一键启动

```bash
# 启动所有服务（PostgreSQL, Redis, 可观测性平台）
make start

# 构建应用
make build BINS=blog-apiserver

# 启动应用
./_output/platforms/$(go env GOOS)/$(go env GOARCH)/blog-apiserver \
  --config configs/blog-apiserver.yaml
```

## 📋 服务清单

### 基础服务
- **PostgreSQL**: localhost:54321
- **Redis**: localhost:56379

### 可观测性服务
- **Grafana**: http://localhost:3000 (admin/admin123)
- **VictoriaMetrics**: http://localhost:8428
- **Tempo**: http://localhost:3200
- **OpenTelemetry Collector**: http://localhost:13133/healthz

## 🔧 管理命令

```bash
# 启动/停止所有服务
make start     # 启动所有服务
make stop      # 停止所有服务
make restart   # 重启所有服务

# 分别管理服务
make infra.start     # 只启动基础服务 (PostgreSQL, Redis)
make infra.stop      # 只停止基础服务

make observability.start  # 只启动可观测性服务
make observability.stop   # 只停止可观测性服务
make observability.logs   # 查看可观测性服务日志
```

## 📊 监控端点

```bash
# 应用指标
curl http://localhost:5556/metrics

# 应用健康检查
curl http://localhost:5556/healthz

# 查看 API 文档
curl http://localhost:5556/docs
```

## 📁 重要目录

```
.
├── configs/
│   ├── blog-apiserver.yaml          # 应用配置
│   ├── otel-collector.yaml          # OpenTelemetry Collector 配置
│   ├── tempo.yaml                   # Grafana Tempo 配置
│   └── grafana/                     # Grafana 配置
├── data/                            # 持久化数据目录
├── logs/                            # 应用日志目录
└── scripts/                         # 启动脚本
    ├── start-all.sh                 # 启动所有服务
    └── stop-all.sh                  # 停止所有服务
```

## 🛠️ 开发流程

1. **准备环境**
   ```bash
   make start  # 启动所有依赖服务
   ```

2. **开发应用**
   ```bash
   # 修改代码后重新构建
   make build BINS=blog-apiserver

   # 启动应用
   ./_output/platforms/$(go env GOOS)/$(go env GOARCH)/blog-apiserver \
     --config configs/blog-apiserver.yaml
   ```

3. **查看监控**
   - 访问 Grafana: http://localhost:3000
   - 查看指标: http://localhost:8428
   - 查看日志: `tail -f logs/blog-apiserver.log`

4. **清理环境**
   ```bash
   make stop  # 停止所有服务
   ```

## 🎯 常用操作

### 查看服务状态
```bash
docker compose -f docker-compose.env.yml ps
docker compose -f docker-compose.observability.yml ps
```

### 查看日志
```bash
# 基础服务日志
docker compose -f docker-compose.env.yml logs -f

# 可观测性服务日志
make observability.logs
```

### 重置数据（危险操作）
```bash
# 删除所有数据
rm -rf data/
make stop
make start
```

## 📚 更多文档

- [OpenTelemetry Collector 使用指南](docs/guide/zh-CN/otel-collector.md)
- [项目架构说明](docs/guide/zh-CN/)

## 🔍 故障排查

1. **端口冲突**
   - 确保 5556, 3000, 8428, 3200 等端口未被占用

2. **Docker 问题**
   - 检查 Docker 是否运行: `docker info`
   - 重启 Docker 服务

3. **权限问题**
   - 确保 data/ 目录有写权限: `chmod -R 755 data/`

4. **内存不足**
   - 确保有足够的内存运行所有服务（建议 4GB+）

---

> 💡 **提示**: 如果只需要基础服务（不需要可观测性），可以使用 `make infra.start`