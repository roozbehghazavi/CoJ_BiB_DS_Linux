# CoJ:BiB Dedicated Server – Docker Setup

Runs **Call of Juarez: Bound in Blood Dedicated Server** inside a Docker
container using Wine, a headless X11 display (Xvfb), Fluxbox window manager,
and x11vnc for remote GUI access.

```
Ubuntu host
└── Docker
    └── coj2-server container
        ├── Xvfb  :99  (virtual display)
        ├── Fluxbox    (window manager)
        ├── x11vnc     (VNC → port 6900)
        └── Wine
            ├── CoJ2Controller.exe   ← you connect to this via VNC
            └── CoJ2Game_x86_ds.exe  ← controller launches this
```

The dedicated server is installed **silently at build time** using Inno Setup's
`/VERYSILENT` flag — no GUI clicks needed. The controller is not an installer;
it's just a folder of files that Wine runs directly.

---

## Prerequisites (host machine)

```bash
sudo apt update && sudo apt install -y docker.io docker-compose-plugin
sudo usermod -aG docker $USER   # log out and back in
```

---

## Directory layout

Prepare this structure **before** running `docker compose build`:

```
coj2-docker/
├── Dockerfile
├── docker-compose.yml
├── .env
│
├── CoJ_BiB_DedicatedServer_setup.exe   ← Inno Setup installer (from ModDB)
│
├── Applications/
│  ├── CoJ2 Controller/            ← just drop the folder here (no installer)
│  │   └── CoJ2Controller.exe
│  └── DedicatedServerMod/         ← engine_x86_ds.dll patch
│
├── scripts/
│   ├── entrypoint.sh
│   ├── launch_controller.sh
│   └── stop_processes.sh
├── config/
│   ├── supervisord.conf
│   └── fluxbox-menu
└── server-data/                        ← persisted logs/configs (auto-created)
```

---

## Configuration (.env)

```env
# VNC password (strongly recommended on public servers)
VNC_PASS=changeme

# Set to "true" to auto-launch the CoJ2 Controller on container start
AUTO_START=false
```

---

## Build & run

```bash
# Build — first time takes ~15 min (winetricks + silent installer)
docker compose build

# Start
docker compose up -d

# Connect VNC client to <your-server-ip>:6900
# Right-click desktop → Launch Controller
```

---

## What happens during `docker build`

1. Ubuntu + Wine stable + Xvfb + Fluxbox + x11vnc installed
2. `wineboot` + `winetricks` set up the Wine prefix with dotnet40, VC runtimes, DirectX
3. The Inno Setup installer runs silently:
   ```
   wine CoJ_BiB_DedicatedServer_setup.exe /VERYSILENT /SUPPRESSMSGBOXES /NORESTART /DIR="C:\Program Files\Techland\..."
   ```
4. The server list mod (`DedicatedServerMod/`) is copied on top
5. Installer `.exe` is deleted — not needed anymore

The controller folder is just copied as-is to `/root/CoJ_BiB_DS_Linux/Applications/CoJ2 Controller/`.

---

## Launching the server

Once connected via VNC:
- **Right-click** desktop → **Launch Controller**

Or from the host:
```bash
docker exec coj2-server /scripts/launch_controller.sh
```

The controller GUI opens in the VNC window and handles starting
`CoJ2Game_x86_ds.exe` internally, just like on Windows.

To auto-launch on every container start set `AUTO_START=true` in `.env`.

---

## Day-to-day commands

| Action | Command |
|--------|---------|
| Start | `docker compose up -d` |
| Stop | `docker compose down` |
| Logs | `docker compose logs -f` |
| Shell | `docker exec -it coj2-server bash` |
| Launch controller | `docker exec coj2-server /scripts/launch_controller.sh` |
| Stop game procs | `docker exec coj2-server /scripts/stop_processes.sh` |

---

## Ports

| Port | Protocol | Purpose |
|------|----------|---------|
| 6900 | TCP | VNC |
| 27632 | UDP | CoJ game traffic |
| 27632 | TCP | CoJ query |

```bash
sudo ufw allow 6900/tcp
sudo ufw allow 27632/udp
sudo ufw allow 27632/tcp
```

---

## Troubleshooting

**Installer fails during build**
The silent installer still needs a display. If Xvfb times out, bump the
`sleep 3` before the `wine ...` installer line in the Dockerfile to `sleep 5`.

**Controller not found**
Verify `CoJ_BiB_DS_Linux/Applications/CoJ2 Controller/CoJ2Controller.exe`
exists before building. Check: `docker exec coj2-server ls "/root/CoJ_BiB_DS_Linux/Applications/CoJ2 Controller/"`

**VNC black screen**
Wait 5–10 seconds after startup, then reconnect.
Check: `docker compose logs coj2-server`

**Game not visible to players**
- Confirm UDP 27632 is open on firewall + cloud security group.
- Verify the mod was applied: `docker exec coj2-server ls "/root/wine-coj2/drive_c/Program Files/Techland/Call of Juarez - Bound in Blood Dedicated Server/"`
