FROM nginx:alpine

# 设置工作目录
WORKDIR /app

# 安装必要的工具
RUN apk add --no-cache \
    jq \
    dcron \
    tzdata \
    curl \
    && rm -rf /var/cache/apk/*

# 复制脚本文件
COPY docker-entrypoint.sh /docker-entrypoint.sh
COPY docker-update-auth.sh /app/scripts/update-auth.sh
COPY docker-setup-cron.sh /app/scripts/setup-cron.sh

# 复制 Nginx 配置模板
COPY nginx-http-proxy.conf /etc/nginx/templates/default.conf.template

# 复制静态文件
COPY www /usr/share/nginx/html

# 创建必要的目录
RUN mkdir -p /var/log/cron \
    && chmod +x /docker-entrypoint.sh \
    && chmod +x /app/scripts/update-auth.sh \
    && chmod +x /app/scripts/setup-cron.sh \
    && chmod -R 755 /usr/share/nginx/html \
    && find /usr/share/nginx/html -type f -exec chmod 644 {} \; \
    && find /usr/share/nginx/html -type d -exec chmod 755 {} \;

# 设置时区（默认北京时间）
ENV TZ=Asia/Shanghai
RUN ln -snf /usr/share/zoneinfo/$TZ /etc/localtime && echo $TZ > /etc/timezone

# 暴露端口
EXPOSE 15000

# 设置入口点
ENTRYPOINT ["/bin/sh", "/docker-entrypoint.sh"]

# 启动 Nginx
CMD ["nginx", "-g", "daemon off;"]

