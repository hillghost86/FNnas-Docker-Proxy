# fnnas-docker-proxy

![License](https://img.shields.io/badge/license-MIT-blue.svg)
![Docker](https://img.shields.io/badge/docker-ready-blue.svg)
![Nginx](https://img.shields.io/badge/nginx-proxy-green.svg)

[![GitHub](https://img.shields.io/badge/GitHub-hillghost86%2Ffnnas--docker--proxy-blue?logo=github)](https://github.com/hillghost86/fnnas-docker-proxy)
[![Gitee](https://img.shields.io/badge/Gitee-hillghost86%2Ffnnas--docker--proxy-red?logo=gitee)](https://gitee.com/hillghost86/fnnas-docker-proxy)

> 使用 Nginx 反向代理为飞牛 NAS (FNNAS) 的 Docker Registry 添加自定义认证 headers，实现局域网内 Docker 镜像加速。

专为飞牛 NAS 的 Docker Registry 设计，支持自动添加认证信息，实现无缝的镜像加速体验。

## 📋 目录

- [功能特性](#-功能特性)
- [快速开始](#-快速开始)
  - [1. 克隆仓库](#1-克隆仓库)
  - [2. 配置认证信息](#2-配置认证信息)
  - [3. 配置日志目录挂载（可选）](#3-配置日志目录挂载可选)
  - [4. 启动代理服务](#4-启动代理服务)
  - [5. 配置 Docker](#5-配置-docker)
  - [6. 重启 Docker Desktop](#6-重启-docker-desktop)
  - [7. 测试](#7-测试)
- [文件说明](#-文件说明)
- [工作原理](#-工作原理)
- [端口说明](#-端口说明)
- [日志](#-日志)
- [故障排查](#-故障排查)
- [注意事项](#-注意事项)

## ✨ 功能特性

- ✅ **自动添加认证 headers** - 自动添加 `X-Meta-Token` 和 `X-Meta-Sign` 认证 headers
- ✅ **重写认证头** - 重写 `WWW-Authenticate` header，确保 Docker 通过代理获取 token
- ✅ **HTTP 协议支持** - 支持 HTTP 协议，无需配置 SSL 证书
- ✅ **局域网部署** - 支持局域网部署（监听 `0.0.0.0:15000`）

## 🚀 快速开始

### 1. 克隆仓库

使用 Git 克隆本项目到本地，可以选择以下任一方式：

**GitHub（推荐）：**

```bash
# HTTPS 方式
git clone https://github.com/hillghost86/fnnas-docker-proxy.git
cd fnnas-docker-proxy
```

```bash
# SSH 方式
git clone git@github.com:hillghost86/fnnas-docker-proxy.git
cd fnnas-docker-proxy
```

**Gitee（国内镜像，访问更快）：**

```bash
# HTTPS 方式
git clone https://gitee.com/hillghost86/fnnas-docker-proxy.git
cd fnnas-docker-proxy
```

```bash
# SSH 方式
git clone git@gitee.com:hillghost86/fnnas-docker-proxy.git
cd fnnas-docker-proxy
```

### 2. 配置认证信息

#### 2.1 从飞牛 NAS 获取认证信息

在飞牛 NAS 上执行以下命令获取认证信息：

```bash
# 查看 config.json 文件位置
sudo cat /root/.docker/config.json
```

文件内容示例：

```json
{
  "HttpHeaders": {
    "X-Meta-Sign": "xxxxxxxxxxxxxxxxxxxxxxxxxxxxxxxx",
    "X-Meta-Token": "eyJleGFtcGxlX3Rva2VuX3BsYWNlaG9sZGVyX2Zvcl9kZW1vX3B1cnBvc2Vfb25seQ=="
  }
}
```

> **⚠️ 注意**：上述示例中的 Token 和 Sign 值已做脱敏处理（使用占位符替代），请使用你实际文件中的值。Token 值通常是 Base64 编码的字符串，Sign 值是 32 位的十六进制字符串。

提取 `HttpHeaders` 中的 `X-Meta-Token` 和 `X-Meta-Sign` 的值。

#### 2.2 配置 .env 文件

复制示例配置文件并编辑：

**Windows (PowerShell):**

```powershell
Copy-Item env.example .env
```

**Linux/macOS:**

```bash
cp env.example .env
```

然后编辑 `.env` 文件，填入你的认证信息和日志配置：

```env
# ============================================
# 认证信息（必填，从 /root/.docker/config.json 获取）
# ============================================
META_TOKEN=你的X-Meta-Token值
META_SIGN=你的X-Meta-Sign值

# ============================================
# 日志开关配置（可选，默认关闭）
# ============================================
ENABLE_ACCESS_LOG=false
ENABLE_ERROR_LOG=false

# ============================================
# 日志文件配置（可选，仅在日志开启时使用）
# ============================================
ACCESS_LOG_NAME=http-proxy-access.log
ERROR_LOG_NAME=http-proxy-error.log

# ============================================
# 日志目录挂载开关（可选，默认开启）
# ============================================
ENABLE_LOG_VOLUME=true
```

> **💡 提示**：配置文件 `nginx-http-proxy.conf` 中已使用环境变量占位符，启动时会自动从 `.env` 文件读取并替换。

### 3. 配置日志目录挂载（可选）

在 `.env` 文件中配置 `ENABLE_LOG_VOLUME`：

- **`ENABLE_LOG_VOLUME=true`**（默认）：挂载日志目录
  - 使用 Docker named volume，**无需手动创建目录**，Docker 会自动创建
  - 日志存储在 Docker 管理的卷中，可通过 `docker volume inspect fnnas-docker-proxy_nginx-logs` 查看位置
  - ⚠️ **注意**：如果日志功能关闭（`ENABLE_ACCESS_LOG=false` 且 `ENABLE_ERROR_LOG=false`），即使挂载了目录也不会写入日志，建议设置为 `false` 以节省资源

- **`ENABLE_LOG_VOLUME=false`**：不挂载日志目录
  - 在 `docker-compose.yml` 中注释掉日志目录挂载行：
    ```yaml
    # - nginx-logs:/var/log/nginx
    ```
  - 同时注释掉 `volumes` 部分中的 `nginx-logs:` 定义
  - 💡 **建议**：如果日志功能关闭，使用此选项以避免创建不必要的 Docker 卷

### 4. 启动代理服务

```bash
docker compose up -d
```

或者使用旧版本的 Docker Compose：

```bash
docker-compose up -d
```

### 5. 配置 Docker

编辑 Docker 配置文件：

**Windows:**

编辑 `%USERPROFILE%\.docker\daemon.json`

**Linux/macOS:**

编辑 `/etc/docker/daemon.json` 或 `~/.docker/daemon.json`

添加以下配置（将镜像源地址替换为你部署的 IP 地址及端口号，本机直接使用 `127.0.0.1:15000`）：

```json
{
  "registry-mirrors": [
    "http://127.0.0.1:15000"
  ],
  "insecure-registries": [
    "127.0.0.1"
  ]
}
```

### 6. 重启 Docker Desktop

**Windows:**

完全退出并重新启动 Docker Desktop，使配置生效。

**Linux:**

```bash
sudo systemctl restart docker
```

**macOS:**

重启 Docker Desktop 应用。

### 7. 测试

测试镜像拉取功能：

```bash
docker pull nginx
```

如果配置成功，镜像将通过代理加速下载。

## 📁 文件说明

| 文件 | 说明 |
|------|------|
| `docker-compose.yml` | Docker Compose 配置文件 |
| `nginx-http-proxy.conf` | Nginx 代理配置模板（使用环境变量占位符） |
| `env.example` | 环境变量配置示例文件（可提交到版本控制） |
| `.env` | 环境变量配置文件（**不要提交到版本控制**） |
| `docker-entrypoint.sh` | 启动脚本（用于替换环境变量） |

## 🔧 工作原理

1. **Docker 请求** - Docker 请求 `http://127.0.0.1:15000/v2/...`
2. **Nginx 代理** - Nginx 代理到 `https://docker.fnnas.com`，自动添加认证 headers
3. **重写认证头** - 返回的 `WWW-Authenticate` header 被重写为 `http://127.0.0.1:15000/service/token`
4. **完成拉取** - Docker 使用重写后的地址获取 token，继续通过代理完成镜像拉取

## 🔌 端口说明

- **15000**: 代理服务监听端口（可在 `docker-compose.yml` 中修改）

> **💡 提示**：如需使用 80 端口，修改 `docker-compose.yml` 中的端口映射为 `"0.0.0.0:80:15000"`，并更新 Docker 配置中的 `registry-mirrors` 为 `http://127.0.0.1:80`

## 📝 日志

日志功能默认**关闭**，可在 `.env` 文件中开启。

### 开启日志

在 `.env` 文件中设置：

```env
ENABLE_ACCESS_LOG=true
ENABLE_ERROR_LOG=true
```

### 配置日志文件名

（仅在日志开启时有效）

```env
ACCESS_LOG_NAME=my-access.log
ERROR_LOG_NAME=my-error.log
```

### 日志文件位置

- 日志文件位于 `nginx-logs/` 目录（通过 Docker 卷挂载）
- **访问日志**：记录所有请求
- **错误日志**：记录错误信息

### 日志目录挂载控制

在 `.env` 文件中设置 `ENABLE_LOG_VOLUME`：

- `true`：挂载日志目录（使用 Docker named volume，**自动创建，无需手动创建目录**）
- `false`：不挂载日志目录（需要在 `docker-compose.yml` 中注释掉日志目录挂载）

> **💡 重要提示**：
> - 如果 `ENABLE_ACCESS_LOG=false` 且 `ENABLE_ERROR_LOG=false`（日志功能关闭），即使 `ENABLE_LOG_VOLUME=true` 挂载了目录，Nginx 也不会写入任何日志（配置为 `off`）
> - **建议**：如果日志功能关闭，同时设置 `ENABLE_LOG_VOLUME=false` 以避免创建不必要的 Docker 卷，节省资源

### 查看日志位置

```bash
# 查看日志卷的位置
docker volume inspect fnnas-docker-proxy_nginx-logs
```

### ⚠️ 注意事项

- 日志功能默认关闭，需要手动开启
- 使用 named volume 时，日志存储在 Docker 管理的卷中，不在项目目录
- 如果 `ENABLE_LOG_VOLUME=false`，需要在 `docker-compose.yml` 中注释掉日志目录挂载行
- 日志文件会持续增长，建议定期清理或配置日志轮转
- **日志开关和挂载开关的关系**：日志开关控制是否写入日志，挂载开关控制是否创建卷。如果日志关闭，建议也关闭挂载以节省资源

## 🔍 故障排查

### 检查代理服务状态

```bash
docker compose ps
docker compose logs
```

### 测试代理响应

```bash
curl -v http://127.0.0.1:15000/v2/
```

应该返回 401 错误，但 `WWW-Authenticate` header 应该指向 `http://127.0.0.1:15000/service/token`。

### 检查 Docker 配置

**Windows (PowerShell):**

```powershell
docker info | Select-String -Pattern "Registry Mirrors|Insecure Registries"
```

**Linux/macOS:**

```bash
docker info | grep -E "Registry Mirrors|Insecure Registries"
```

## ⚠️ 注意事项

- ✅ 认证信息存储在 `.env` 文件中，**不要提交到版本控制系统**
- ✅ 如果修改了 `nginx-http-proxy.conf`，需要重启服务才能生效：
  ```bash
  docker compose restart
  ```
- ✅ 修改 `.env` 文件后，需要重启服务：
  ```bash
  docker compose down
  docker compose up -d
  ```

---

**⭐ 如果这个项目对你有帮助，欢迎 Star！**
