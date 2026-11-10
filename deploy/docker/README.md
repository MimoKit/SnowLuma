# Docker 运行镜像

SnowLuma 通过注入本地 QQ 进程工作，所以容器里必须同时有 Linux QQ。这个镜像包含
Linux QQ、Xvfb、VNC/noVNC、supervisord 和 SnowLuma 发行包，扫码登录走浏览器里的 noVNC。

镜像由 [`.github/workflows/docker-image.yml`](../../.github/workflows/docker-image.yml)
从已发布的 Release 构建，不重新编译源码：

- `SnowLuma-<tag>-linux-x64.tar.gz` / `SnowLuma-<tag>-linux-arm64.tar.gz`
- Linux QQ 安装包来自 `Rodert/qq-versions` 镜像发布（腾讯会定期从 CDN 下架旧版本）

## 端口

| 端口 | 用途 |
| --- | --- |
| `5099` | SnowLuma WebUI |
| `6081` | noVNC（浏览器登录 QQ） |
| `5900` | VNC |
| `3000` | OneBot HTTP 默认端口 |
| `3001` | OneBot WebSocket 默认端口 |

## 启动

```bash
docker compose -f deploy/docker/docker-compose.yml up -d
```

或直接 `docker run`：

```bash
docker run -d \
  --name snowluma \
  --restart unless-stopped \
  --shm-size 1g \
  --cap-add SYS_PTRACE \
  --security-opt seccomp=unconfined \
  -p 5099:5099 -p 6081:6081 -p 5900:5900 -p 3000:3000 -p 3001:3001 \
  -v snowluma-data:/app/data \
  -v snowluma-home:/app/home \
  ghcr.io/mimokit/snowluma:latest
```

`SYS_PTRACE` 是必需的：注入器要用 ptrace 附加到 QQ 进程。

## 首次使用

1. 打开 `http://<host>:6081/` 连上 noVNC（默认 VNC 密码 `snowluma`，用 `VNC_PASSWD` 修改）。
2. 在容器内 QQ 上扫码登录。登录态保存在 `/app/home` 卷里，重启不会丢。
3. 打开 `http://<host>:5099/`，初始管理员密码在 `docker logs snowluma` 里，只打印一次。

`SNOWLUMA_HOOK_AUTOLOAD=1` 已经打开：QQ 登录后 hook 会自动附着并接管账号，不需要在
WebUI 里手动 Load。

## 数据卷

| 路径 | 内容 |
| --- | --- |
| `/app/data` | SnowLuma 配置、日志、消息与媒体（工作目录） |
| `/app/home` | QQ 与 SnowLuma 的用户目录（登录态、`~/.config`、`~/.local`） |

## 手动重建镜像

在 Actions 里手动触发 `Docker Image` 工作流，填入要重建的 Release tag 即可；
`snowluma_tag` 必须已经有一个带 Linux 压缩包的 Release。
