# ================================================================
# Call of Juarez: Bound in Blood – Dedicated Server
# Ubuntu 24.04 + Wine (Stable) + Xvfb + Fluxbox + x11vnc
# ================================================================
FROM ubuntu:24.04

LABEL maintainer="coj2-server"
LABEL description="CoJ:BiB Dedicated Server via Wine + VNC"

ENV DEBIAN_FRONTEND=noninteractive
ENV TZ=UTC

ENV DISPLAY=:99
ENV WINEPREFIX=/root/wine-coj2
ENV WINEARCH=win32
ENV WINEDEBUG=-all
ENV XDG_RUNTIME_DIR=/tmp/runtime-root
ENV VNC_PORT=6900
ENV COJ_PORT=27632
ENV RESOLUTION=1280x1024x24

# ── 1. System packages + Wine repo ──────────────────────────────
RUN apt-get update && apt-get install -y \
        software-properties-common wget curl cabextract gnupg2 \
        apt-transport-https ca-certificates x11-utils \
        xvfb x11vnc fluxbox xauth xinit dbus-x11 unzip net-tools \
        procps supervisor \
    && dpkg --add-architecture i386 \
    && mkdir -pm755 /etc/apt/keyrings \
    && wget -qO /etc/apt/keyrings/winehq-archive.key \
        https://dl.winehq.org/wine-builds/winehq.key \
    && wget -qNP /etc/apt/sources.list.d/ \
        https://dl.winehq.org/wine-builds/ubuntu/dists/noble/winehq-noble.sources \
    && apt-get update \
    && apt-get install -y --install-recommends winehq-stable winbind \
    && apt-get autoremove -y && apt-get clean \
    && rm -rf /var/lib/apt/lists/*

# ── 2. Winetricks ────────────────────────────────────────────────
RUN wget -qO /usr/local/bin/winetricks \
        https://raw.githubusercontent.com/Winetricks/winetricks/master/src/winetricks \
    && chmod +x /usr/local/bin/winetricks

# ── 3. Wine prefix + all dependencies (including dotnet40) ──────
#    No display needed for wineboot or winetricks — mirrors the
#    working setup_wine.sh exactly. Xvfb is only required later
#    when launching actual GUI apps (installer, controller).
COPY scripts/wine_setup.sh /tmp/wine_setup.sh
RUN chmod +x /tmp/wine_setup.sh && /tmp/wine_setup.sh

# ── 4. Copy installer + controller + mod ────────────────────────
#
#    Files needed beside the Dockerfile:
#
#    CoJ_BiB_DedicatedServer_setup.exe        ← Inno Setup installer
#
#    Applications/
#     ├── CoJ2 Controller/                 ← folder of files (not an installer)
#     │   └── CoJ2Controller.exe
#     └── DedicatedServerMod/              ← engine_x86_ds.dll patch
#
COPY CoJ_BiB_DedicatedServer_setup.exe /tmp/CoJ_BiB_DedicatedServer_setup.exe
COPY Applications/    /root/CoJ_BiB_DS_Linux/Applications/

# ── 5. Silent install of the dedicated server ───────────────────
COPY scripts/install_server.sh /tmp/install_server.sh
RUN chmod +x /tmp/install_server.sh && /tmp/install_server.sh

# ── 6. Apply server list mod ─────────────────────────────────────
RUN cp -r /root/CoJ_BiB_DS_Linux/Applications/DedicatedServerMod/. \
    "/root/wine-coj2/drive_c/Program Files/Techland/Call of Juarez - Bound in Blood Dedicated Server/"

# ── 7. Runtime scripts & config ──────────────────────────────────
COPY scripts/entrypoint.sh        /entrypoint.sh
COPY scripts/launch_controller.sh /scripts/launch_controller.sh
COPY scripts/stop_processes.sh    /scripts/stop_processes.sh
COPY config/supervisord.conf      /etc/supervisor/conf.d/coj2.conf
COPY config/fluxbox-menu          /root/.fluxbox/menu

RUN chmod +x /entrypoint.sh \
              /scripts/launch_controller.sh \
              /scripts/stop_processes.sh

# ── Ports ────────────────────────────────────────────────────────
EXPOSE 6900        
EXPOSE 27632/udp   
EXPOSE 27632/tcp  

ENTRYPOINT ["/entrypoint.sh"]