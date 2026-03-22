-- 初始化数据库脚本
-- 在容器首次启动时自动执行

-- 创建扩展
CREATE EXTENSION IF NOT EXISTS "uuid-ossp";
CREATE EXTENSION IF NOT EXISTS "pg_stat_statements";
CREATE EXTENSION IF NOT EXISTS "pg_trgm";

-- 创建示例 schema
CREATE SCHEMA IF NOT EXISTS app;

-- 设置搜索路径
ALTER DATABASE devdb SET search_path TO app, public;

-- 创建示例表
CREATE TABLE IF NOT EXISTS app.users (
    id UUID PRIMARY KEY DEFAULT uuid_generate_v4(),
    username VARCHAR(50) NOT NULL UNIQUE,
    email VARCHAR(100) NOT NULL UNIQUE,
    password_hash VARCHAR(255) NOT NULL,
    is_active BOOLEAN DEFAULT true,
    created_at TIMESTAMP WITH TIME ZONE DEFAULT CURRENT_TIMESTAMP,
    updated_at TIMESTAMP WITH TIME ZONE DEFAULT CURRENT_TIMESTAMP
);

CREATE TABLE IF NOT EXISTS app.roles (
    id SERIAL PRIMARY KEY,
    name VARCHAR(50) NOT NULL UNIQUE,
    description TEXT
);

CREATE TABLE IF NOT EXISTS app.user_roles (
    user_id UUID REFERENCES app.users(id) ON DELETE CASCADE,
    role_id INTEGER REFERENCES app.roles(id) ON DELETE CASCADE,
    PRIMARY KEY (user_id, role_id)
);

-- 创建索引
CREATE INDEX IF NOT EXISTS idx_users_email ON app.users(email);
CREATE INDEX IF NOT EXISTS idx_users_username ON app.users(username);
CREATE INDEX IF NOT EXISTS idx_users_created_at ON app.users(created_at);

-- 插入示例数据
INSERT INTO app.roles (name, description) VALUES 
    ('admin', '系统管理员'),
    ('user', '普通用户'),
    ('guest', '访客')
ON CONFLICT (name) DO NOTHING;

-- 创建自动更新时间戳函数
CREATE OR REPLACE FUNCTION update_updated_at_column()
RETURNS TRIGGER AS $$
BEGIN
    NEW.updated_at = CURRENT_TIMESTAMP;
    RETURN NEW;
END;
$$ LANGUAGE plpgsql;

-- 创建触发器
CREATE TRIGGER update_users_updated_at
    BEFORE UPDATE ON app.users
    FOR EACH ROW
    EXECUTE FUNCTION update_updated_at_column();

-- 授予权限
GRANT ALL PRIVILEGES ON SCHEMA app TO devuser;
GRANT ALL PRIVILEGES ON ALL TABLES IN SCHEMA app TO devuser;
GRANT ALL PRIVILEGES ON ALL SEQUENCES IN SCHEMA app TO devuser;