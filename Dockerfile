# ================================================================
# Call of Juarez: Bound in Blood – Dedicated Server
# Ubuntu 24.04 + Wine (Stable) + Xvfb + Fluxbox + x11vnc
# ================================================================
FROM ubuntu:24.04

LABEL maintainer="coj2-server"
LABEL description="CoJ:BiB Dedicated Server via Wine + VNC"

# Prevent interactive prompts during apt installs
ENV DEBIAN_FRONTEND=noninteractive
ENV TZ=UTC

# ── Runtime environment ──────────────────────────────────────────
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
        apt-transport-https ca-certificates \
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

# ── 3. Bootstrap Wine prefix (headless, no GUI needed) ──────────
#    Xvfb is required even during build for wineboot / winetricks
RUN mkdir -p "$XDG_RUNTIME_DIR" && chmod 700 "$XDG_RUNTIME_DIR" \
    && Xvfb :99 -ac -screen 0 1280x1024x24 & \
       sleep 3 \
    && wineboot --init \
    && sleep 5 \
    # Install runtime components
    && winetricks -q \
        dotnet40 \
        vcrun2005 vcrun2008 vcrun2010 vcrun2012 vcrun2013 vcrun2015 \
        d3dx9_43 d3dcompiler_43 \
        corefonts mfc42 \
        win10 \
    && winetricks nocrashdialog \
    # DirectDraw → OpenGL
    && wine reg add "HKCU\\Software\\Wine\\Direct3D" \
        /v DirectDrawRenderer /t REG_SZ /d opengl /f \
    # Kill the build-time Xvfb
    && pkill Xvfb || true \
    && rm -rf /tmp/.X99-lock /tmp/runtime-root

# ── 4. Copy game files ───────────────────────────────────────────
#
#    Expected layout next to this Dockerfile:
#
#      CoJ_BiB_DS_Linux/
#      └── Applications/
#          ├── CoJ2 Controller/      ← controller GUI (CoJ2Controller.exe)
#          └── DedicatedServerMod/   ← engine_x86_ds.dll patch
#
#      CoJ_BiB_Server/               ← your pre-installed dedicated server folder
#      │                                (copy from Windows:
#      │                                 C:\Program Files (x86)\Techland\
#      │                                 Call of Juarez - Bound in Blood Dedicated Server\)
#      ├── CoJ2Game_x86_ds.exe
#      ├── engine_x86_ds.dll
#      └── ...
#
#    NO installer is run. The pre-installed folder is copied straight
#    into the Wine prefix just like the installer would have placed it.

# Controller GUI + mod tools (accessed at runtime by launch_controller.sh)
COPY --chown=root:root CoJ_BiB_DS_Linux/Applications/ /root/CoJ_BiB_DS_Linux/Applications/

# Pre-installed dedicated server → drop directly into Wine's Program Files.
# Matches the path the Windows installer creates, so the controller finds it.
COPY --chown=root:root CoJ_BiB_Server/ \
    "/root/wine-coj2/drive_c/Program Files/Techland/Call of Juarez - Bound in Blood Dedicated Server/"

# Apply the server list mod on top (overwrites engine_x86_ds.dll + any other patched files)
RUN cp -r /root/CoJ_BiB_DS_Linux/Applications/DedicatedServerMod/. \
    "/root/wine-coj2/drive_c/Program Files/Techland/Call of Juarez - Bound in Blood Dedicated Server/"

# ── 5. Scripts & supervisor config ──────────────────────────────
COPY scripts/entrypoint.sh  /entrypoint.sh
COPY scripts/launch_controller.sh /scripts/launch_controller.sh
COPY scripts/stop_processes.sh    /scripts/stop_processes.sh
COPY config/supervisord.conf      /etc/supervisor/conf.d/coj2.conf
COPY config/fluxbox-menu          /root/.fluxbox/menu

RUN chmod +x /entrypoint.sh \
              /scripts/launch_controller.sh \
              /scripts/stop_processes.sh

# ── Ports ────────────────────────────────────────────────────────
# VNC
EXPOSE 6900
# CoJ game / query
EXPOSE 27632/udp
EXPOSE 27632/tcp

ENTRYPOINT ["/entrypoint.sh"]
