--
-- MinBlog v4 - Go技术栈优化版数据库结构
-- Modules: 验证码 + 用户管理 + 系统监控
-- Generated: 2025-12-18
-- Database: PostgreSQL 16+
-- Description: 包含完整注释的数据库设计文档
--
-- 基础设置
SET statement_timeout = 0;
SET lock_timeout = 0;
SET idle_in_transaction_session_timeout = 0;
SET client_encoding = 'UTF8';
SET standard_conforming_strings = ON;
-- 设置默认搜索路径，优先使用 public schema
SELECT pg_catalog.set_config ('search_path', 'public', FALSE);
SET check_function_bodies = FALSE;
SET xmloption = CONTENT;
SET client_min_messages = warning;
SET row_security = OFF;
-- 注意：
-- 1. 此脚本需要在 minblog_v4 数据库中执行
-- 2. 请先手动创建数据库：CREATE DATABASE minblog_v4;
-- 3. 然后在此数据库中执行此脚本
-- 基础配置
SET default_tablespace = '';
SET default_table_access_method = heap;
-- 启用UUID扩展
CREATE EXTENSION IF NOT EXISTS "uuid-ossp";
-- 清理现有表 (按依赖关系倒序删除)
DROP TABLE IF EXISTS public.sys_user_config;
DROP TABLE IF EXISTS public.sys_user;
DROP TABLE IF EXISTS public.casbin_rule;
DROP TABLE IF EXISTS public.sys_login_log;
DROP TABLE IF EXISTS public.sys_monitor;
-- =========================
-- 用户管理模块 (User Management)
-- =========================
-- 用户表
-- Description: 系统用户基础信息表，存储用户的基本资料和认证信息
-- 使用说明:
--   - id: 用于内部逻辑关联和统计查询，性能最优
--   - uuid: 用于API接口和外部展示，保证安全性
--   - password: 存储bcrypt加密后的密码，不可明文存储
--   - is_superuser: 超级管理员标志，拥有系统所有权限
--   - is_active: 用户状态，false表示用户被禁用无法登录
CREATE TABLE public.sys_user (
    -- 自增主键，内部逻辑使用，性能最优
    id BIGSERIAL PRIMARY KEY,
    -- UUID，API接口展示，保证安全性和分布式唯一性
    user_id UUID NOT NULL DEFAULT uuid_generate_v4 () UNIQUE,
    -- 用户名，登录时使用，系统内唯一
    username VARCHAR (50) NOT NULL UNIQUE,
    -- 密码，bcrypt加密存储
    PASSWORD VARCHAR (128) NOT NULL,
    -- 邮箱地址，用于找回密码和通知
    email VARCHAR (255) NULL UNIQUE,
    -- 手机号码，用于短信验证和通知
    phone VARCHAR (20) NULL UNIQUE,
    -- 用户头像URL
    avatar VARCHAR (500) NULL,
    -- 性别: 0=未知, 1=男, 2=女
    gender SMALLINT NOT NULL DEFAULT 0,
    -- 用户状态: 0=正常, 1=锁定, 2=禁用, 3=注销
    status SMALLINT NOT NULL DEFAULT 0,
    -- 最后登录时间，用于活跃度统计
    last_login_at TIMESTAMPTZ,
    -- 创建时间，自动生成
    created_at TIMESTAMPTZ NOT NULL DEFAULT CURRENT_TIMESTAMP,
    -- 更新时间，自动更新
    updated_at TIMESTAMPTZ NOT NULL DEFAULT CURRENT_TIMESTAMP,
    -- 用户描述或备注信息
    description TEXT
);
-- 用户表注释
COMMENT ON TABLE sys_user IS '用户基础信息表，存储用户认证信息和基本资料';
-- 用户表索引
CREATE INDEX idx_sys_user_status ON sys_user (status);
CREATE INDEX idx_sys_user_status_created ON sys_user (status, created_at DESC);
CREATE INDEX idx_sys_user_status_last_login ON sys_user (status, last_login_at DESC);
-- =========================
-- Casbin权限控制模块 (Casbin Authorization Module)
-- =========================
-- Casbin规则表
-- Description: 存储Casbin权限策略规则，作为系统中唯一的权限控制机制
-- 使用说明:
--   - 基于"主体, 对象, 动作"模型 (subject, object, action)
--   - 支持多种策略类型: p=权限策略, g=组/角色继承
--   - 所有权限控制通过此表实现，无需传统RBAC表
--   - 支持动态权限管理，修改后立即生效
CREATE TABLE public.casbin_rule (
    -- 自增主键，用于内部关联
    id BIGSERIAL PRIMARY KEY,
    -- 策略类型: p=权限策略, g=角色继承策略
    ptype VARCHAR (100) NOT NULL,
    -- 主体(用户名/角色名)或策略字段0
    v0 VARCHAR (100),
    -- 对象(资源路径)或策略字段1
    v1 VARCHAR (100),
    -- 动作(HTTP方法)或策略字段2
    v2 VARCHAR (100),
    -- 扩展策略字段，用于复杂场景
    v3 VARCHAR (100),
    -- 扩展策略字段，用于复杂场景
    v4 VARCHAR (100),
    -- 扩展策略字段，用于复杂场景
    v5 VARCHAR (100)
);
-- Casbin规则表注释
COMMENT ON TABLE casbin_rule IS 'Casbin权限规则表，作为系统中唯一的权限控制机制，支持RBAC和ABAC策略';
-- Casbin规则表索引
CREATE INDEX idx_casbin_rule_ptype ON casbin_rule (ptype);
CREATE INDEX idx_casbin_rule_ptype_v0_v1 ON casbin_rule (ptype, v0, v1);
CREATE INDEX idx_casbin_rule_ptype_v0_v1_v2 ON casbin_rule (ptype, v0, v1, v2);
CREATE INDEX idx_casbin_rule_g_v0 ON casbin_rule (ptype, v0)
WHERE ptype = 'g';
-- 用户登录日志表
-- Description: 记录用户每次登录的详细信息，用于安全审计和统计分析
-- 使用说明:
--   - 记录成功和失败的登录尝试
--   - 包含IP地址、设备信息等安全相关信息
--   - 用于异常登录检测和安全分析
CREATE TABLE public.sys_login_log (
    -- 自增主键
    id BIGSERIAL PRIMARY KEY,
    -- 登录用户名，失败时可能用户不存在
    username VARCHAR (50),
    -- 登录IP地址，用于安全分析
    ip_address INET,
    -- 完整的User-Agent字符串
    user_agent VARCHAR (1000),
    -- 登录状态: true=成功, false=失败
    status BOOLEAN NOT NULL,
    -- 登录失败错误信息，成功时为空
    error_message TEXT,
    -- 登录时间
    created_at TIMESTAMPTZ NOT NULL DEFAULT CURRENT_TIMESTAMP
);
-- 登录日志表注释
COMMENT ON TABLE sys_login_log IS '用户登录日志表，记录登录尝试和安全信息';
-- 登录日志表索引
CREATE INDEX idx_sys_login_log_user_created ON sys_login_log (username, created_at DESC);
CREATE INDEX idx_sys_login_log_status_created ON sys_login_log (status, created_at DESC);
CREATE INDEX idx_sys_login_log_ip_created ON sys_login_log (ip_address, created_at DESC);
CREATE INDEX idx_sys_login_log_user_status ON sys_login_log (username, status);
CREATE INDEX idx_sys_login_log_username ON sys_login_log (username);
-- 用户个人配置表
-- Description: 存储用户的个人偏好设置和配置信息
-- 使用说明:
--   - config_value使用JSONB格式，支持灵活配置
--   - 支持主题、语言、通知设置等个人配置
--   - 每个用户可以有多个配置项
CREATE TABLE public.sys_user_config (
    -- 自增主键
    id BIGSERIAL PRIMARY KEY,
    -- 用户UUID，级联删除
    user_id UUID NOT NULL REFERENCES sys_user (user_id) ON DELETE CASCADE,
    -- 配置项键名，如"theme"、"language"
    config_key VARCHAR (100) NOT NULL,
    -- 配置项值，JSON格式，支持复杂配置
    config_value JSONB NOT NULL,
    -- 创建时间
    created_at TIMESTAMPTZ NOT NULL DEFAULT CURRENT_TIMESTAMP,
    -- 更新时间
    updated_at TIMESTAMPTZ NOT NULL DEFAULT CURRENT_TIMESTAMP,
    -- 用户UUID+配置键唯一约束
    UNIQUE (user_id, config_key)
);
-- 用户配置表注释
COMMENT ON TABLE sys_user_config IS '用户个人配置表，存储用户偏好设置';
-- 用户配置表索引说明：唯一约束已自动创建索引，无需额外索引
-- =========================
-- 系统监控模块 (System Monitor Module)
-- =========================
-- 系统监控表
-- Description: 记录服务器系统资源使用情况，用于性能监控和容量规划
-- 使用说明:
--   - 定时收集系统资源数据
--   - 用于性能分析和告警
--   - 支持多服务器监控
CREATE TABLE public.sys_monitor (
    -- 自增主键
    id BIGSERIAL PRIMARY KEY,
    -- 服务器名称，便于标识
    server_name VARCHAR (100),
    -- 服务器IP地址
    server_ip INET,
    -- CPU使用率，百分比
    cpu_usage DECIMAL (5, 2) NOT NULL,
    -- CPU核心数
    cpu_cores INTEGER,
    -- 内存使用率，百分比
    memory_usage DECIMAL (5, 2) NOT NULL,
    -- 内存总量，字节为单位
    memory_total BIGINT,
    -- 已用内存，字节为单位
    memory_used BIGINT,
    -- 磁盘使用率，百分比
    disk_usage DECIMAL (5, 2) NOT NULL,
    -- 磁盘总量，字节为单位
    disk_total BIGINT,
    -- 已用磁盘，字节为单位
    disk_used BIGINT,
    -- 网络接收字节数
    network_rx BIGINT DEFAULT 0,
    -- 网络发送字节数
    network_tx BIGINT DEFAULT 0,
    -- 系统负载平均值，1分钟
    load_avg_1 DECIMAL (5, 2),
    -- 系统运行时间，秒为单位
    uptime BIGINT,
    -- 进程数量
    process_count INTEGER,
    -- 监控时间
    created_at TIMESTAMPTZ NOT NULL DEFAULT CURRENT_TIMESTAMP
);
-- 系统监控表注释
COMMENT ON TABLE sys_monitor IS '系统监控表，记录服务器资源使用情况';
-- 系统监控表索引
CREATE INDEX idx_sys_monitor_server_created ON sys_monitor (server_ip, created_at DESC);
CREATE INDEX idx_sys_monitor_created_at ON sys_monitor (created_at DESC);
CREATE INDEX idx_sys_monitor_high_cpu ON sys_monitor (created_at DESC)
WHERE cpu_usage > 80.0;
CREATE INDEX idx_sys_monitor_high_memory ON sys_monitor (created_at DESC)
WHERE memory_usage > 80.0;
-- 注释：索引已移至对应表定义之后，遵循就近原则
-- =========================
-- 注释：updated_at 字段更新逻辑移至应用层处理
-- =========================
-- =========================
-- 初始数据 (Initial Data)
-- =========================
-- 创建默认超级管理员用户 (密码: admin123)
-- Description: 创建系统默认管理员账户，密码为admin123，请及时修改
-- 注意：默认密码较弱，生产环境请立即修改
INSERT INTO sys_user (
        username,
        PASSWORD,
        email,
        phone,
        description
    )
VALUES (
        'admin',
        '$2a$10$92IXUNpkjO0rOQ5byMi.Ye4oKoEa3Ro9llC/.og/at2.uheWG/igi',
        'admin@minblog.local',
        '+8613800138000',
        '系统默认超级管理员账户，创建于系统初始化'
    );
-- =========================
-- Casbin权限规则初始数据 (Casbin Rule Initial Data)
-- =========================
-- 用户角色绑定规则 (g策略)
-- Description: 定义用户与角色的绑定关系，格式: g, user, role
INSERT INTO casbin_rule (ptype, v0, v1, v2)
VALUES (
        'g',
        'admin',
        'r:super_admin',
        NULL
    );
-- 角色权限策略 (p策略)
-- Description: 定义角色对资源的访问权限，格式: p, role, resource, action
INSERT INTO casbin_rule (ptype, v0, v1, v2)
VALUES -- 超级管理员权限 (r:super_admin)
    (
        'p',
        'r:super_admin',
        '/api/v1/*',
        'GET'
    ),
    (
        'p',
        'r:super_admin',
        '/api/v1/*',
        'POST'
    ),
    (
        'p',
        'r:super_admin',
        '/api/v1/*',
        'PUT'
    ),
    (
        'p',
        'r:super_admin',
        '/api/v1/*',
        'DELETE'
    ),
    -- 系统监控权限 (所有角色可用)
    (
        'p',
        'r:admin',
        '/api/v1/monitor/*',
        'GET'
    ),
    (
        'p',
        'r:user',
        '/api/v1/monitor/*',
        'GET'
    ),
    -- Casbin规则管理权限 (仅超级管理员)
    (
        'p',
        'r:super_admin',
        '/api/v1/casbin/rules',
        'GET'
    ),
    (
        'p',
        'r:super_admin',
        '/api/v1/casbin/rules',
        'POST'
    ),
    (
        'p',
        'r:super_admin',
        '/api/v1/casbin/rules/*',
        'PUT'
    ),
    (
        'p',
        'r:super_admin',
        '/api/v1/casbin/rules/*',
        'DELETE'
    ),
    (
        'p',
        'r:super_admin',
        '/api/v1/casbin/sync',
        'POST'
    ),
    -- 日志查看权限 (管理员及以上)
    (
        'p',
        'r:admin',
        '/api/v1/logs/*',
        'GET'
    ),
    (
        'p',
        'r:user',
        '/api/v1/logs/login',
        'GET'
    ),
    -- 用户个人权限 (所有用户)
    (
        'p',
        '*',
        '/api/v1/users/profile',
        'GET'
    ),
    (
        'p',
        '*',
        '/api/v1/users/profile',
        'PUT'
    );