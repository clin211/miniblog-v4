-- MinBlog v4 - 数据库初始化脚本
-- Description: 创建 minblog_v4 数据库并设置基础配置
-- Usage: 先执行此脚本创建数据库，再执行 basic.sql 创建表结构

-- 创建 minblog_v4 数据库
DROP DATABASE IF EXISTS minblog_v4;
CREATE DATABASE minblog_v4
    WITH TEMPLATE = template0
    ENCODING = 'UTF8'
    LOCALE_PROVIDER = libc
    LOCALE = 'en_US.utf8';

-- 添加数据库注释
COMMENT ON DATABASE minblog_v4 IS 'MinBlog v4 - Go技术栈博客系统数据库，采用简化架构设计，包含验证码、用户管理、系统监控和Casbin权限控制模块';

-- 设置数据库所有者
ALTER DATABASE minblog_v4 OWNER TO postgres;

-- 输出成功信息
DO $$
BEGIN
    RAISE NOTICE '数据库 minblog_v4 创建成功！';
    RAISE NOTICE '接下来请执行：psql -d minblog_v4 -f basic.sql';
END $$;