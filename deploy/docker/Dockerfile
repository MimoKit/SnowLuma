# syntax=docker/dockerfile:1

# SnowLuma attaches to a QQ process that has to run on the same machine, so the
# runtime image carries the Linux QQ client, a virtual X server and VNC access
# for logging the account in. The SnowLuma bundle and the QQ package are staged
# into the build context by .github/workflows/docker-image.yml:
#
#   qq/<arch>.deb              Linux QQ client for the target architecture
#   snowluma/<arch>.tar.gz     SnowLuma release bundle (ships its own Node.js)
#
# Both architecture keys are the Docker architecture names (amd64, arm64).

FROM debian:bookworm-slim

ARG TARGETARCH
ARG SNOWLUMA_VERSION=latest

ENV DEBIAN_FRONTEND=noninteractive \
    LANG=C.UTF-8 \
    TZ=Asia/Shanghai \
    DISPLAY=:1 \
    HOME=/app/home \
    XDG_RUNTIME_DIR=/run/snowluma \
    SNOWLUMA_HOME=/opt/snowluma \
    SNOWLUMA_WEBUI_HOST=0.0.0.0 \
    SNOWLUMA_WEBUI_PORT=5099 \
    SNOWLUMA_HOOK_AUTOLOAD=1 \
    SNOWLUMA_SCREEN=1920x1080 \
    VNC_PASSWD=snowluma

# Client runtime plus the virtual display stack. The Qt/GTK libraries are what
# the Linux QQ build links against; dropping any of them only surfaces later, at
# QQ startup, so they are installed here in one pass.
RUN set -eux; \
    apt-get update; \
    apt-get install -y --no-install-recommends \
        ca-certificates \
        curl \
        dbus \
        dbus-x11 \
        fontconfig \
        fonts-wqy-zenhei \
        fluxbox \
        libasound2 \
        libatk-bridge2.0-0 \
        libatk1.0-0 \
        libatspi2.0-0 \
        libcairo2 \
        libcups2 \
        libdrm2 \
        libgbm1 \
        libglib2.0-0 \
        libgtk-3-0 \
        libnotify4 \
        libnss3 \
        libpango-1.0-0 \
        libsecret-1-0 \
        libvulkan1 \
        libxcomposite1 \
        libxdamage1 \
        libxfixes3 \
        libxkbcommon0 \
        libxrandr2 \
        libxss1 \
        libxtst6 \
        novnc \
        procps \
        supervisor \
        tini \
        tzdata \
        websockify \
        x11vnc \
        xdg-utils \
        xvfb; \
    ln -sf "/usr/share/zoneinfo/${TZ}" /etc/localtime; \
    echo "${TZ}" > /etc/timezone; \
    rm -rf /var/lib/apt/lists/*

# apt resolves the package's own dependencies, so no `dpkg -i` + `-f install`
# retry loop is needed here.
COPY qq/${TARGETARCH}.deb /tmp/linuxqq.deb
RUN set -eux; \
    apt-get update; \
    apt-get install -y --no-install-recommends /tmp/linuxqq.deb; \
    rm -f /tmp/linuxqq.deb; \
    rm -rf /var/lib/apt/lists/*; \
    command -v qq

COPY snowluma/${TARGETARCH}.tar.gz /tmp/snowluma.tar.gz
RUN set -eux; \
    mkdir -p "${SNOWLUMA_HOME}"; \
    tar -xzf /tmp/snowluma.tar.gz -C "${SNOWLUMA_HOME}"; \
    rm -f /tmp/snowluma.tar.gz; \
    test -f "${SNOWLUMA_HOME}/index.mjs"; \
    test -x "${SNOWLUMA_HOME}/node"

# One unprivileged account owns both processes: the hook injects into QQ, which
# only works when QQ and SnowLuma run as the same user.
RUN set -eux; \
    groupadd --gid 1000 snowluma; \
    useradd --no-log-init --uid 1000 --gid 1000 --home-dir /app/home --shell /bin/bash snowluma; \
    mkdir -p /app/data /app/home /run/snowluma /tmp/.X11-unix; \
    chown -R snowluma:snowluma /app /opt/snowluma /run/snowluma; \
    if [ -d /opt/QQ ]; then chown -R snowluma:snowluma /opt/QQ; fi; \
    chmod 700 /run/snowluma; \
    chmod 1777 /tmp/.X11-unix

COPY supervisord.conf /etc/supervisord.conf
COPY start.sh /usr/local/bin/snowluma-entrypoint
RUN chmod +x /usr/local/bin/snowluma-entrypoint

LABEL org.opencontainers.image.title="SnowLuma" \
      org.opencontainers.image.version="${SNOWLUMA_VERSION}" \
      org.opencontainers.image.description="SnowLuma OneBot runtime with the Linux QQ client, Xvfb and noVNC"

# SnowLuma keeps data/, logs/ and config/ relative to its working directory.
WORKDIR /app/data

EXPOSE 5099 3000 3001 5900 6081

VOLUME ["/app/data", "/app/home"]

ENTRYPOINT ["/usr/bin/tini", "--", "/usr/local/bin/snowluma-entrypoint"]
