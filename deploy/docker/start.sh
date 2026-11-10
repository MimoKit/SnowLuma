#!/usr/bin/env bash
# Container entrypoint: prepares the X/VNC stack and hands over to supervisord,
# which keeps Xvfb, QQ and SnowLuma alive together.
set -euo pipefail

: "${VNC_PASSWD:=snowluma}"
: "${SNOWLUMA_HOME:=/opt/snowluma}"
: "${SNOWLUMA_WEBUI_PORT:=5099}"

export HOME="${HOME:-/app/home}"
export DISPLAY="${DISPLAY:-:1}"
export XDG_RUNTIME_DIR="${XDG_RUNTIME_DIR:-/run/snowluma}"
export SNOWLUMA_HOOK_RUNTIME_DIR="${SNOWLUMA_HOOK_RUNTIME_DIR:-${XDG_RUNTIME_DIR}}"

mkdir -p "${HOME}" "${XDG_RUNTIME_DIR}" /app/data /tmp/.X11-unix /var/log/snowluma
chmod 700 "${XDG_RUNTIME_DIR}"
chmod 1777 /tmp/.X11-unix

# Mounted volumes arrive owned by root; hand them over once instead of walking
# (and re-chowning) message history and media on every start.
for dir in "${HOME}" /app/data; do
    if [ "$(stat -c %U "${dir}")" != "snowluma" ]; then
        chown -R snowluma:snowluma "${dir}"
    fi
done

x11vnc -storepasswd "${VNC_PASSWD}" /etc/x11vnc.pass >/dev/null 2>&1
chmod 600 /etc/x11vnc.pass

# A container restart keeps the writable layer, so stale X locks would make
# Xvfb refuse the display.
rm -f /tmp/.X1-lock "/tmp/.X11-unix/X1"

# QQ and SnowLuma share one session bus; dbus-launch exports it in the parent
# environment that supervisord passes to both children.
eval "$(dbus-launch --sh-syntax)"
export DBUS_SESSION_BUS_ADDRESS

echo "SnowLuma ${SNOWLUMA_HOME}: WebUI port ${SNOWLUMA_WEBUI_PORT}, noVNC port 6081, VNC port 5900"

exec /usr/bin/supervisord -c /etc/supervisord.conf
