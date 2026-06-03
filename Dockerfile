# ================================================================
# Call of Juarez: Bound in Blood – Dedicated Server
# Multi-stage build to minimize final image size
#
# Stage 1 (builder): installs everything, runs winetricks + installer
# Stage 2 (runtime): copies only what's needed to run, strips the rest
# ================================================================

# ── STAGE 1: builder ────────────────────────────────────────────
FROM ubuntu:24.04 AS builder

ENV DEBIAN_FRONTEND=noninteractive
ENV TZ=UTC
ENV DISPLAY=:99
ENV WINEPREFIX=/root/wine-coj2
ENV WINEARCH=win32
ENV WINEDEBUG=-all
ENV XDG_RUNTIME_DIR=/tmp/runtime-root

# Install everything needed to BUILD (apt tools, winetricks deps, x11-utils for xdpyinfo)
RUN apt-get update && apt-get install -y \
        software-properties-common wget curl cabextract gnupg2 \
        apt-transport-https ca-certificates x11-utils \
        xvfb xauth dbus-x11 \
    && dpkg --add-architecture i386 \
    && mkdir -pm755 /etc/apt/keyrings \
    && wget -qO /etc/apt/keyrings/winehq-archive.key \
        https://dl.winehq.org/wine-builds/winehq.key \
    && wget -qNP /etc/apt/sources.list.d/ \
        https://dl.winehq.org/wine-builds/ubuntu/dists/noble/winehq-noble.sources \
    && apt-get update \
    && apt-get install -y --install-recommends winehq-stable winbind \
    # Purge build-only tools and docs that won't be needed in the final image
    && apt-get purge -y \
        software-properties-common gnupg2 apt-transport-https \
    && apt-get autoremove -y \
    && apt-get clean \
    && rm -rf \
        /var/lib/apt/lists/* \
        /usr/share/doc \
        /usr/share/man \
        /usr/share/locale \
        /usr/share/info \
        # Wine's 64-bit binaries — we run WINEARCH=win32 only
        /opt/wine-stable/lib64 \
        /opt/wine-stable/bin/wine64 \
        /opt/wine-stable/bin/wine64-preloader

# Winetricks
RUN wget -qO /usr/local/bin/winetricks \
        https://raw.githubusercontent.com/Winetricks/winetricks/master/src/winetricks \
    && chmod +x /usr/local/bin/winetricks

# Wine prefix + all dependencies
COPY scripts/wine_setup.sh /tmp/wine_setup.sh
RUN chmod +x /tmp/wine_setup.sh && /tmp/wine_setup.sh \
    # Wipe winetricks download cache — already extracted into the prefix
    && rm -rf /root/.cache/winetricks \
    # Wipe Wine's gecko/mono installers if downloaded
    && rm -rf /root/.cache/wine \
    # Wipe tmp leftovers
    && rm -rf /tmp/*

# Copy installer + controller + mod
COPY CoJ_BiB_DedicatedServer_setup.exe /tmp/CoJ_BiB_DedicatedServer_setup.exe
COPY Applications/    /root/CoJ_BiB_DS_Linux/Applications/

# Silent install — script deletes the .exe itself at the end
COPY scripts/install_server.sh /tmp/install_server.sh
RUN chmod +x /tmp/install_server.sh && /tmp/install_server.sh \
    && rm -f /tmp/install_server.sh

# Apply server list mod
RUN cp -r /root/CoJ_BiB_DS_Linux/Applications/DedicatedServerMod/. \
    "/root/wine-coj2/drive_c/Program Files/Techland/Call of Juarez - Bound in Blood Dedicated Server/" \
    # Strip Windows debug symbols from the prefix if present
    && find /root/wine-coj2 -name "*.pdb" -delete \
    # Remove Wine's fake C: temp and installer leftovers
    && rm -rf "/root/wine-coj2/drive_c/windows/temp/"* \
    && rm -rf "/root/wine-coj2/drive_c/users/root/Temp/"*


# ── STAGE 2: runtime ────────────────────────────────────────────
FROM ubuntu:24.04 AS runtime

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

# Install ONLY what's needed to RUN (no build tools, no winetricks, no wget)
RUN apt-get update && apt-get install -y \
        # X11 display stack
        xvfb x11vnc fluxbox \
        # Wine runtime requirements
        ca-certificates xauth dbus-x11 \
        winbind \
        # Utilities used by scripts
        procps net-tools \
        # 32-bit arch for Wine libs
    && dpkg --add-architecture i386 \
    && apt-get update \
    && apt-get install -y \
        # 32-bit libs Wine needs at runtime
        libglib2.0-0:i386 \
        libnss3:i386 \
        libgnutls30:i386 \
        libpulse0:i386 \
        libfontconfig1:i386 \
        libfreetype6:i386 \
        libxcomposite1:i386 \
        libxcursor1:i386 \
        libxrandr2:i386 \
        libxi6:i386 \
        libxext6:i386 \
    && apt-get autoremove -y \
    && apt-get clean \
    && rm -rf \
        /var/lib/apt/lists/* \
        /usr/share/doc \
        /usr/share/man \
        /usr/share/locale \
        /usr/share/info

# Copy Wine — WineHQ installs entirely under /opt/wine-stable;
# /usr/bin/wine etc. are just symlinks into it.
COPY --from=builder /opt/wine-stable /opt/wine-stable
# Recreate the symlinks that the WineHQ deb would normally make
RUN ln -sf /opt/wine-stable/bin/wine        /usr/bin/wine       && \
    ln -sf /opt/wine-stable/bin/wineserver  /usr/bin/wineserver && \
    ln -sf /opt/wine-stable/bin/wineboot    /usr/bin/wineboot   && \
    ln -sf /opt/wine-stable/bin/winepath    /usr/bin/winepath   && \
    ln -sf /opt/wine-stable/bin/winedbg     /usr/bin/winedbg    && \
    ln -sf /opt/wine-stable/bin/winecfg     /usr/bin/winecfg

# Copy the fully-built Wine prefix (has dotnet40, vcrun, game installed)
COPY --from=builder /root/wine-coj2           /root/wine-coj2

# Copy controller files
COPY --from=builder /root/CoJ_BiB_DS_Linux    /root/CoJ_BiB_DS_Linux

# Runtime scripts & config
COPY scripts/entrypoint.sh        /entrypoint.sh
COPY scripts/launch_controller.sh /scripts/launch_controller.sh
COPY scripts/stop_processes.sh    /scripts/stop_processes.sh
COPY config/supervisord.conf      /etc/supervisor/conf.d/coj2.conf
COPY config/fluxbox-menu          /root/.fluxbox/menu

RUN chmod +x /entrypoint.sh \
              /scripts/launch_controller.sh \
              /scripts/stop_processes.sh

EXPOSE 6900
EXPOSE 27632/udp
EXPOSE 27632/tcp

# Declare volumes AFTER files are copied — if declared before, Docker
# initialises the volume empty and wipes the files that were copied in.
VOLUME ["/root/wine-coj2/drive_c/Program Files/Techland/Call of Juarez - Bound in Blood Dedicated Server"]
VOLUME ["/root/CoJ_BiB_DS_Linux/Applications/CoJ2 Controller"]

ENTRYPOINT ["/entrypoint.sh"]


# ── STAGE 3: flatten ────────────────────────────────────────────
# Each RUN in stage 2 created a layer. Even files deleted in later
# RUN steps are still stored in earlier layers and bloat the image.
# Copying everything from scratch into a single layer erases all
# that history — only the final filesystem state survives.
FROM scratch AS final

COPY --from=runtime / /

# Re-declare ENV, EXPOSE, ENTRYPOINT — they don't carry over from COPY
ENV DISPLAY=:99
ENV WINEPREFIX=/root/wine-coj2
ENV WINEARCH=win32
ENV WINEDEBUG=-all
ENV XDG_RUNTIME_DIR=/tmp/runtime-root
ENV VNC_PORT=6900
ENV COJ_PORT=27632
ENV RESOLUTION=1280x1024x24

EXPOSE 6900
EXPOSE 27632/udp
EXPOSE 27632/tcp

VOLUME ["/root/wine-coj2/drive_c/Program Files/Techland/Call of Juarez - Bound in Blood Dedicated Server/CoJ2/Data/MapsNet"]

ENTRYPOINT ["/entrypoint.sh"]