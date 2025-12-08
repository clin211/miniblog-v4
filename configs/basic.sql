/*
 Navicat Premium Dump SQL
 
 Source Server         : soybean-postgres
 Source Server Type    : PostgreSQL
 Source Server Version : 140019 (140019)
 Source Host           : localhost:15432
 Source Catalog        : soybean
 Source Schema         : public
 
 Target Server Type    : PostgreSQL
 Target Server Version : 140019 (140019)
 File Encoding         : 65001
 
 Date: 11/11/2025 22:37:12
 */
-- ----------------------------
-- sys_api_id_seq 序列结构
-- ----------------------------
DROP SEQUENCE IF EXISTS "public"."sys_api_id_seq";
CREATE SEQUENCE "public"."sys_api_id_seq" INCREMENT 1 MINVALUE 1 MAXVALUE 9223372036854775807 START 1 CACHE 1;
ALTER SEQUENCE "public"."sys_api_id_seq" OWNER TO "postgres";
-- ----------------------------
-- sys_button_id_seq 序列结构
-- ----------------------------
DROP SEQUENCE IF EXISTS "public"."sys_button_id_seq";
CREATE SEQUENCE "public"."sys_button_id_seq" INCREMENT 1 MINVALUE 1 MAXVALUE 9223372036854775807 START 1 CACHE 1;
ALTER SEQUENCE "public"."sys_button_id_seq" OWNER TO "postgres";
-- ----------------------------
-- sys_menu_id_seq 序列结构
-- ----------------------------
DROP SEQUENCE IF EXISTS "public"."sys_menu_id_seq";
CREATE SEQUENCE "public"."sys_menu_id_seq" INCREMENT 1 MINVALUE 1 MAXVALUE 9223372036854775807 START 1 CACHE 1;
ALTER SEQUENCE "public"."sys_menu_id_seq" OWNER TO "postgres";
-- ----------------------------
-- sys_role_id_seq 序列结构
-- ----------------------------
DROP SEQUENCE IF EXISTS "public"."sys_role_id_seq";
CREATE SEQUENCE "public"."sys_role_id_seq" INCREMENT 1 MINVALUE 1 MAXVALUE 9223372036854775807 START 1 CACHE 1;
ALTER SEQUENCE "public"."sys_role_id_seq" OWNER TO "postgres";
-- ----------------------------
-- sys_users_id_seq 序列结构
-- ----------------------------
DROP SEQUENCE IF EXISTS "public"."sys_users_id_seq";
CREATE SEQUENCE "public"."sys_users_id_seq" INCREMENT 1 MINVALUE 1 MAXVALUE 9223372036854775807 START 1 CACHE 1;
ALTER SEQUENCE "public"."sys_users_id_seq" OWNER TO "postgres";
-- ----------------------------
-- sys_api 表结构
-- ----------------------------
DROP TABLE IF EXISTS "public"."sys_api";
CREATE TABLE "public"."sys_api" (
    "id" int8 NOT NULL DEFAULT nextval('sys_api_id_seq'::regclass),
    "created_at" int8,
    "updated_at" int8,
    "deleted_at" int8 DEFAULT 0,
    "menu_id" int8,
    "name" varchar(50) COLLATE "pg_catalog"."default" NOT NULL,
    "desc" varchar(100) COLLATE "pg_catalog"."default",
    "method" varchar(50) COLLATE "pg_catalog"."default" NOT NULL,
    "path" varchar(100) COLLATE "pg_catalog"."default" NOT NULL,
    "auth" varchar(1) COLLATE "pg_catalog"."default" DEFAULT '2'::character varying
);
ALTER TABLE "public"."sys_api" OWNER TO "postgres";
-- sys_api 的索引和约束
ALTER SEQUENCE "public"."sys_api_id_seq" OWNED BY "public"."sys_api"."id";
SELECT setval('"public"."sys_api_id_seq"', 140, true);
CREATE INDEX "idx_sys_api_deleted_at" ON "public"."sys_api" USING btree (
    "deleted_at" "pg_catalog"."int8_ops" ASC NULLS LAST
);
CREATE UNIQUE INDEX "key_method_path" ON "public"."sys_api" USING btree (
    "method" COLLATE "pg_catalog"."default" "pg_catalog"."text_ops" ASC NULLS LAST,
    "path" COLLATE "pg_catalog"."default" "pg_catalog"."text_ops" ASC NULLS LAST
);
ALTER TABLE "public"."sys_api"
ADD CONSTRAINT "sys_api_pkey" PRIMARY KEY ("id");
-- sys_api 的列注释
COMMENT ON COLUMN "public"."sys_api"."created_at" IS '创建时间';
COMMENT ON COLUMN "public"."sys_api"."updated_at" IS '更新时间';
COMMENT ON COLUMN "public"."sys_api"."deleted_at" IS '是否删除';
COMMENT ON COLUMN "public"."sys_api"."menu_id" IS '菜单id';
COMMENT ON COLUMN "public"."sys_api"."name" IS '权限名称';
COMMENT ON COLUMN "public"."sys_api"."desc" IS '权限描述';
COMMENT ON COLUMN "public"."sys_api"."method" IS 'HTTP方法(GET,POST,PUT,DELETE)';
COMMENT ON COLUMN "public"."sys_api"."path" IS '路由路径(比如/api/users)';
COMMENT ON COLUMN "public"."sys_api"."auth" IS '是否需要权限1需要2不需要';
-- ----------------------------
-- sys_button 表结构
-- ----------------------------
DROP TABLE IF EXISTS "public"."sys_button";
CREATE TABLE "public"."sys_button" (
    "id" int8 NOT NULL DEFAULT nextval('sys_button_id_seq'::regclass),
    "created_at" int8,
    "updated_at" int8,
    "deleted_at" int8 DEFAULT 0,
    "menu_id" int8,
    "label" varchar(50) COLLATE "pg_catalog"."default" NOT NULL,
    "code" varchar(50) COLLATE "pg_catalog"."default" NOT NULL
);
ALTER TABLE "public"."sys_button" OWNER TO "postgres";
-- sys_button 的索引和约束
ALTER SEQUENCE "public"."sys_button_id_seq" OWNED BY "public"."sys_button"."id";
SELECT setval('"public"."sys_button_id_seq"', 3, true);
CREATE UNIQUE INDEX "idx_sys_button_code" ON "public"."sys_button" USING btree (
    "code" COLLATE "pg_catalog"."default" "pg_catalog"."text_ops" ASC NULLS LAST
);
CREATE INDEX "idx_sys_button_deleted_at" ON "public"."sys_button" USING btree (
    "deleted_at" "pg_catalog"."int8_ops" ASC NULLS LAST
);
ALTER TABLE "public"."sys_button"
ADD CONSTRAINT "sys_button_pkey" PRIMARY KEY ("id");
-- sys_button 的列注释
COMMENT ON COLUMN "public"."sys_button"."created_at" IS '创建时间';
COMMENT ON COLUMN "public"."sys_button"."updated_at" IS '更新时间';
COMMENT ON COLUMN "public"."sys_button"."deleted_at" IS '是否删除';
COMMENT ON COLUMN "public"."sys_button"."menu_id" IS '菜单id';
COMMENT ON COLUMN "public"."sys_button"."label" IS '按钮名';
COMMENT ON COLUMN "public"."sys_button"."code" IS '按钮代码';
-- ----------------------------
-- sys_menu 表结构
-- ----------------------------
DROP TABLE IF EXISTS "public"."sys_menu";
CREATE TABLE "public"."sys_menu" (
    "id" int8 NOT NULL DEFAULT nextval('sys_menu_id_seq'::regclass),
    "created_at" int8,
    "updated_at" int8,
    "deleted_at" int8 DEFAULT 0,
    "create_by_user_id" int8,
    "update_by_user_id" int8,
    "parent_id" int8 NOT NULL,
    "menu_type" text COLLATE "pg_catalog"."default" NOT NULL,
    "menu_name" text COLLATE "pg_catalog"."default" NOT NULL,
    "route_name" text COLLATE "pg_catalog"."default" NOT NULL,
    "route_path" text COLLATE "pg_catalog"."default" NOT NULL,
    "component" text COLLATE "pg_catalog"."default" NOT NULL,
    "i18_n_key" text COLLATE "pg_catalog"."default" NOT NULL,
    "icon_type" text COLLATE "pg_catalog"."default" NOT NULL,
    "icon" varchar(50) COLLATE "pg_catalog"."default" NOT NULL,
    "status" varchar(1) COLLATE "pg_catalog"."default" NOT NULL DEFAULT '1'::character varying,
    "keep_alive" bool NOT NULL,
    "constant" bool NOT NULL,
    "order_by" int8 NOT NULL,
    "href" varchar(100) COLLATE "pg_catalog"."default" NOT NULL,
    "fixed_index_in_tab" int8 NOT NULL,
    "hide_in_menu" bool NOT NULL,
    "active_menu" text COLLATE "pg_catalog"."default" NOT NULL,
    "multi_tab" bool NOT NULL,
    "query" jsonb
);
ALTER TABLE "public"."sys_menu" OWNER TO "postgres";
-- sys_menu 的索引和约束
ALTER SEQUENCE "public"."sys_menu_id_seq" OWNED BY "public"."sys_menu"."id";
SELECT setval('"public"."sys_menu_id_seq"', 24, true);
CREATE INDEX "idx_sys_menu_deleted_at" ON "public"."sys_menu" USING btree (
    "deleted_at" "pg_catalog"."int8_ops" ASC NULLS LAST
);
CREATE UNIQUE INDEX "idx_sys_menu_route_name" ON "public"."sys_menu" USING btree (
    "route_name" COLLATE "pg_catalog"."default" "pg_catalog"."text_ops" ASC NULLS LAST
);
ALTER TABLE "public"."sys_menu"
ADD CONSTRAINT "sys_menu_pkey" PRIMARY KEY ("id");
-- sys_menu 的列注释
COMMENT ON COLUMN "public"."sys_menu"."created_at" IS '创建时间';
COMMENT ON COLUMN "public"."sys_menu"."updated_at" IS '更新时间';
COMMENT ON COLUMN "public"."sys_menu"."deleted_at" IS '是否删除';
COMMENT ON COLUMN "public"."sys_menu"."create_by_user_id" IS '创建人id';
COMMENT ON COLUMN "public"."sys_menu"."update_by_user_id" IS '更新人id';
COMMENT ON COLUMN "public"."sys_menu"."parent_id" IS '父菜单ID,如果为0则为一级菜单';
COMMENT ON COLUMN "public"."sys_menu"."menu_type" IS '菜单类型1目录2菜单';
COMMENT ON COLUMN "public"."sys_menu"."menu_name" IS '菜单名称';
COMMENT ON COLUMN "public"."sys_menu"."route_name" IS '路由名称';
COMMENT ON COLUMN "public"."sys_menu"."route_path" IS '路由路径';
COMMENT ON COLUMN "public"."sys_menu"."component" IS '组件名称';
COMMENT ON COLUMN "public"."sys_menu"."i18_n_key" IS '国际化key';
COMMENT ON COLUMN "public"."sys_menu"."icon_type" IS '图标类型1iconify图标你2本地图标';
COMMENT ON COLUMN "public"."sys_menu"."icon" IS '图标';
COMMENT ON COLUMN "public"."sys_menu"."status" IS '菜单状态1启用2禁用';
COMMENT ON COLUMN "public"."sys_menu"."keep_alive" IS '是否缓存路由';
COMMENT ON COLUMN "public"."sys_menu"."constant" IS '是否常量路由';
COMMENT ON COLUMN "public"."sys_menu"."order_by" IS '排序,在同级路由中，越小越靠前';
COMMENT ON COLUMN "public"."sys_menu"."href" IS '外链地址';
COMMENT ON COLUMN "public"."sys_menu"."fixed_index_in_tab" IS '固定在标签页中的序号';
COMMENT ON COLUMN "public"."sys_menu"."hide_in_menu" IS '是否隐藏菜单';
COMMENT ON COLUMN "public"."sys_menu"."active_menu" IS '高亮的菜单';
COMMENT ON COLUMN "public"."sys_menu"."multi_tab" IS '是否支持多页签';
COMMENT ON COLUMN "public"."sys_menu"."query" IS '路由参数';
-- ----------------------------
-- sys_role 表结构
-- ----------------------------
DROP TABLE IF EXISTS "public"."sys_role";
CREATE TABLE "public"."sys_role" (
    "id" int8 NOT NULL DEFAULT nextval('sys_role_id_seq'::regclass),
    "created_at" int8,
    "updated_at" int8,
    "deleted_at" int8 DEFAULT 0,
    "create_by_user_id" int8,
    "update_by_user_id" int8,
    "name" varchar(50) COLLATE "pg_catalog"."default" NOT NULL,
    "code" varchar(50) COLLATE "pg_catalog"."default" NOT NULL,
    "desc" varchar(100) COLLATE "pg_catalog"."default",
    "status" text COLLATE "pg_catalog"."default" DEFAULT '1'::text,
    "home_menu_id" int8 DEFAULT 1
);
ALTER TABLE "public"."sys_role" OWNER TO "postgres";
-- sys_role 的索引和约束
ALTER SEQUENCE "public"."sys_role_id_seq" OWNED BY "public"."sys_role"."id";
SELECT setval('"public"."sys_role_id_seq"', 5, true);
CREATE UNIQUE INDEX "idx_sys_role_code" ON "public"."sys_role" USING btree (
    "code" COLLATE "pg_catalog"."default" "pg_catalog"."text_ops" ASC NULLS LAST
);
CREATE INDEX "idx_sys_role_deleted_at" ON "public"."sys_role" USING btree (
    "deleted_at" "pg_catalog"."int8_ops" ASC NULLS LAST
);
CREATE UNIQUE INDEX "idx_sys_role_name" ON "public"."sys_role" USING btree (
    "name" COLLATE "pg_catalog"."default" "pg_catalog"."text_ops" ASC NULLS LAST
);
ALTER TABLE "public"."sys_role"
ADD CONSTRAINT "sys_role_pkey" PRIMARY KEY ("id");
-- sys_role 的列注释
COMMENT ON COLUMN "public"."sys_role"."created_at" IS '创建时间';
COMMENT ON COLUMN "public"."sys_role"."updated_at" IS '更新时间';
COMMENT ON COLUMN "public"."sys_role"."deleted_at" IS '是否删除';
COMMENT ON COLUMN "public"."sys_role"."create_by_user_id" IS '创建人id';
COMMENT ON COLUMN "public"."sys_role"."update_by_user_id" IS '更新人id';
COMMENT ON COLUMN "public"."sys_role"."name" IS '角色名称';
COMMENT ON COLUMN "public"."sys_role"."code" IS '角色编码';
COMMENT ON COLUMN "public"."sys_role"."desc" IS '角色描述';
COMMENT ON COLUMN "public"."sys_role"."status" IS '是否启用0禁用1启用';
COMMENT ON COLUMN "public"."sys_role"."home_menu_id" IS '首页菜单id';
-- ----------------------------
-- sys_role_apis 表结构
-- ----------------------------
DROP TABLE IF EXISTS "public"."sys_role_apis";
CREATE TABLE "public"."sys_role_apis" (
    "role_id" int8 NOT NULL,
    "api_id" int8 NOT NULL
);
ALTER TABLE "public"."sys_role_apis" OWNER TO "postgres";
-- sys_role_apis 的索引和约束
ALTER TABLE "public"."sys_role_apis"
ADD CONSTRAINT "sys_role_apis_pkey" PRIMARY KEY ("role_id", "api_id");
-- ----------------------------
-- sys_role_buttons 表结构
-- ----------------------------
DROP TABLE IF EXISTS "public"."sys_role_buttons";
CREATE TABLE "public"."sys_role_buttons" (
    "role_id" int8 NOT NULL,
    "button_id" int8 NOT NULL
);
ALTER TABLE "public"."sys_role_buttons" OWNER TO "postgres";
-- sys_role_buttons 的索引和约束
ALTER TABLE "public"."sys_role_buttons"
ADD CONSTRAINT "sys_role_buttons_pkey" PRIMARY KEY ("role_id", "button_id");
-- ----------------------------
-- sys_role_menus 表结构
-- ----------------------------
DROP TABLE IF EXISTS "public"."sys_role_menus";
CREATE TABLE "public"."sys_role_menus" (
    "role_id" int8 NOT NULL,
    "menu_id" int8 NOT NULL
);
ALTER TABLE "public"."sys_role_menus" OWNER TO "postgres";
-- sys_role_menus 的索引和约束
ALTER TABLE "public"."sys_role_menus"
ADD CONSTRAINT "sys_role_menus_pkey" PRIMARY KEY ("role_id", "menu_id");
-- ----------------------------
-- sys_user_roles 表结构
-- ----------------------------
DROP TABLE IF EXISTS "public"."sys_user_roles";
CREATE TABLE "public"."sys_user_roles" (
    "role_id" int8 NOT NULL,
    "user_id" int8 NOT NULL
);
ALTER TABLE "public"."sys_user_roles" OWNER TO "postgres";
-- sys_user_roles 的索引和约束
ALTER TABLE "public"."sys_user_roles"
ADD CONSTRAINT "sys_user_roles_pkey" PRIMARY KEY ("role_id", "user_id");
-- ----------------------------
-- sys_users 表结构
-- ----------------------------
DROP TABLE IF EXISTS "public"."sys_users";
CREATE TABLE "public"."sys_users" (
    "id" int8 NOT NULL DEFAULT nextval('sys_users_id_seq'::regclass),
    "created_at" int8,
    "updated_at" int8,
    "deleted_at" int8 DEFAULT 0,
    "create_by_id" int8,
    "update_by_id" int8,
    "user_name" varchar(50) COLLATE "pg_catalog"."default" NOT NULL,
    "password" varchar(100) COLLATE "pg_catalog"."default" NOT NULL,
    "status" varchar(1) COLLATE "pg_catalog"."default" DEFAULT '1'::character varying,
    "user_gender" varchar(1) COLLATE "pg_catalog"."default" DEFAULT '1'::character varying,
    "nick_name" varchar(50) COLLATE "pg_catalog"."default",
    "user_phone" varchar(11) COLLATE "pg_catalog"."default",
    "user_email" varchar(50) COLLATE "pg_catalog"."default",
    "last_login_time" int8
);
ALTER TABLE "public"."sys_users" OWNER TO "postgres";
-- sys_users 的索引和约束
ALTER SEQUENCE "public"."sys_users_id_seq" OWNED BY "public"."sys_users"."id";
SELECT setval('"public"."sys_users_id_seq"', 1, true);
CREATE INDEX "idx_sys_users_deleted_at" ON "public"."sys_users" USING btree (
    "deleted_at" "pg_catalog"."int8_ops" ASC NULLS LAST
);
CREATE UNIQUE INDEX "idx_sys_users_user_name" ON "public"."sys_users" USING btree (
    "user_name" COLLATE "pg_catalog"."default" "pg_catalog"."text_ops" ASC NULLS LAST
);
ALTER TABLE "public"."sys_users"
ADD CONSTRAINT "sys_users_pkey" PRIMARY KEY ("id");
-- sys_users 的列注释
COMMENT ON COLUMN "public"."sys_users"."created_at" IS '创建时间';
COMMENT ON COLUMN "public"."sys_users"."updated_at" IS '更新时间';
COMMENT ON COLUMN "public"."sys_users"."deleted_at" IS '是否删除';
COMMENT ON COLUMN "public"."sys_users"."create_by_id" IS '创建人id';
COMMENT ON COLUMN "public"."sys_users"."update_by_id" IS '更新人id';
COMMENT ON COLUMN "public"."sys_users"."status" IS '是否启用0禁用1启用';
COMMENT ON COLUMN "public"."sys_users"."user_gender" IS '性别1男2女';
COMMENT ON COLUMN "public"."sys_users"."nick_name" IS '昵称';
COMMENT ON COLUMN "public"."sys_users"."user_phone" IS '手机号';
COMMENT ON COLUMN "public"."sys_users"."user_email" IS '邮箱';