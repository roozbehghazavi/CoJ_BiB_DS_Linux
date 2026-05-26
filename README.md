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

**No GUI installer needed.** The pre-installed game folder is copied directly
into the Wine prefix at build time. Just drop the folders next to the
Dockerfile, build once, and run.

---

## Prerequisites (host machine)

```bash
# Ubuntu 24/26
sudo apt update && sudo apt install -y docker.io docker-compose-plugin
sudo usermod -aG docker $USER   # log out and back in after this
```

---

## Directory layout

Prepare this structure **before** running `docker compose build`:

```
coj2-docker/
├── Dockerfile
├── docker-compose.yml
├── .env                          ← create this (see below)
│
├── CoJ_BiB_DS_Linux/
│   └── Applications/
│       ├── CoJ2 Controller/      ← controller GUI (CoJ2Controller.exe, etc.)
│       └── DedicatedServerMod/   ← engine_x86_ds.dll patch + any other mod files
│
├── CoJ_BiB_Server/               ← your pre-installed dedicated server folder
│   │                                (the output of the Windows installer)
│   ├── CoJ2Game_x86_ds.exe
│   ├── engine_x86_ds.dll
│   └── ...
│
├── scripts/
│   ├── entrypoint.sh
│   ├── launch_controller.sh
│   └── stop_processes.sh
├── config/
│   ├── supervisord.conf
│   └── fluxbox-menu
└── server-data/                  ← persisted logs / server configs (auto-created)
```

### Where to get the pre-installed folder

Install the dedicated server once on a Windows machine (or via Wine on your
current setup), then copy the output folder:

```
C:\Program Files (x86)\Techland\Call of Juarez - Bound in Blood Dedicated Server\
```

Rename/copy that folder to `CoJ_BiB_Server/` next to the Dockerfile.
The Dockerfile copies it straight into the same path inside the Wine prefix.

---

## Configuration (.env file)

Create a `.env` file next to `docker-compose.yml`:

```env
# VNC password (strongly recommended on any public-facing server)
VNC_PASS=changeme

# Set to "true" to auto-launch the CoJ2 Controller when the container starts
AUTO_START=false
```

---

## Build & run

```bash
# 1. Build the image
#    First build takes ~15 min (winetricks installs dotnet40, VC runtimes, etc.)
#    Subsequent builds use the cache and are fast.
docker compose build

# 2. Start the container
docker compose up -d

# 3. Connect via VNC
#    <your-server-ip>:6900
#    You'll see the Fluxbox desktop. Right-click → Launch Controller.
```

---

## Launching the server

Once connected via VNC, either:

- **Right-click** the desktop → **Launch Controller**
- Or run from the host:

```bash
docker exec coj2-server /scripts/launch_controller.sh
```

The controller GUI opens in the VNC window. Use it exactly as you would on
Windows — it handles starting/stopping `CoJ2Game_x86_ds.exe` internally.

To auto-launch on every container start, set `AUTO_START=true` in `.env` and
restart the container.

---

## Day-to-day commands

| Action | Command |
|--------|---------|
| Start container | `docker compose up -d` |
| Stop container | `docker compose down` |
| View logs | `docker compose logs -f` |
| Open a shell | `docker exec -it coj2-server bash` |
| Launch controller | `docker exec coj2-server /scripts/launch_controller.sh` |
| Stop game procs | `docker exec coj2-server /scripts/stop_processes.sh` |
| Restart container | `docker compose restart` |

---

## Updating game files

Because the game files are **baked into the image** (not a bind mount), any
update to `CoJ_BiB_Server/` or `CoJ_BiB_DS_Linux/` requires a rebuild:

```bash
# After updating files on the host:
docker compose down
docker compose build
docker compose up -d
```

Only the `COPY` layers rebuild — Wine prefix layers are cached and reused.

---

## Ports

| Port | Protocol | Purpose |
|------|----------|---------|
| 6900 | TCP | VNC remote desktop |
| 27632 | UDP | CoJ game traffic |
| 27632 | TCP | CoJ query traffic |

Open on your firewall:

```bash
sudo ufw allow 6900/tcp
sudo ufw allow 27632/udp
sudo ufw allow 27632/tcp
```

---

## Persistent data

| What | Where (host) |
|------|-------------|
| Game files | Baked into the image at build time |
| Server logs / configs | `./server-data/` (bind mount, survives restarts) |

---

## Troubleshooting

**VNC shows a black screen**
Wait 5–10 seconds; Xvfb may still be initialising. Check:
```bash
docker compose logs coj2-server
```

**Controller window doesn't appear**
Make sure your VNC client is connected first, then launch the controller.
Check the log inside the container:
```bash
docker exec coj2-server cat /var/log/coj2controller.log
```

**Wine crashes / DLL errors**
Exec into the container and run winetricks manually:
```bash
docker exec -it coj2-server bash
DISPLAY=:99 winetricks vcrun2015
```

**Game server not visible to players**
- Confirm UDP 27632 is open on host firewall AND your cloud security group.
- Ensure the server list mod (`engine_x86_ds.dll`) was applied — the Dockerfile
  does this automatically from `DedicatedServerMod/`.
