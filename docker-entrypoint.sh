#!/bin/sh
set -e

# 如果日志目录挂载存在，确保目录可写（Docker 会自动创建挂载点，但需要确保权限）
if [ -d "/var/log/nginx" ]; then
    # 确保目录可写
    chmod 755 /var/log/nginx 2>/dev/null || true
fi

# 复制模板文件到临时位置（因为原文件是只读的）
cp /etc/nginx/templates/default.conf.template /tmp/default.conf.template

# 替换配置文件中的环境变量
sed -i "s|\${META_TOKEN}|${META_TOKEN}|g" /tmp/default.conf.template
sed -i "s|\${META_SIGN}|${META_SIGN}|g" /tmp/default.conf.template

# 根据环境变量设置日志配置
# 访问日志
if [ "${ENABLE_ACCESS_LOG}" = "true" ]; then
    ACCESS_LOG_CONFIG="/var/log/nginx/${ACCESS_LOG_NAME:-http-proxy-access.log}"
else
    ACCESS_LOG_CONFIG="off"
fi

# 错误日志
if [ "${ENABLE_ERROR_LOG}" = "true" ]; then
    ERROR_LOG_CONFIG="/var/log/nginx/${ERROR_LOG_NAME:-http-proxy-error.log}"
else
    ERROR_LOG_CONFIG="off"
fi

# 替换日志配置占位符
sed -i "s|\${ACCESS_LOG_CONFIG}|${ACCESS_LOG_CONFIG}|g" /tmp/default.conf.template
sed -i "s|\${ERROR_LOG_CONFIG}|${ERROR_LOG_CONFIG}|g" /tmp/default.conf.template

# 将处理后的配置复制到目标位置
cp /tmp/default.conf.template /etc/nginx/conf.d/default.conf

# 执行 nginx
exec nginx -g 'daemon off;'

