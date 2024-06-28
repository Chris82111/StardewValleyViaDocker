# Stardew Valley via Docker

<p align="center">
  <img src="https://img.shields.io/badge/Version-1.6-blue" />
   <a href="https://github.com/Chris82111/SMAPIDedicatedServerMod/releases/tag/v1.1.0-beta"><img src="https://img.shields.io/badge/Mod-v1.1.0--beta-blue"/></a>
</p>

With this repository you can run Stardew Valley as a multiplayer server in a Docker container. [Stardew Valley](https://www.gog.com/de/game/stardew_valley), [SMAPI](https://smapi.io/), the multiplayer mod [SMAPIDedicatedServerMod](https://github.com/ObjectManagerManager/SMAPIDedicatedServerMod) and all server applications are installed automatically. The server is hidden behind a VPN connection. Each client must connect to the server with [WireGuard](https://www.wireguard.com/). In the directory `wireguard` you will find the necessary WireGuard certificates. After someone is connected, it is possible to use Stardew Valley ([GOG](https://www.gog.com/de/game/stardew_valley), [Steam](https://store.steampowered.com/app/413150/Stardew_Valley/)), [TigerVNC](https://tigervnc.org/) and [noVNC](https://novnc.com/info.html). To use the applications on the server, you must run WireGuard VPN and connect with the internal VPN IP address `10.8.0.1` and the correct port. With the connection you can only access the container, you cannot access anything on the server or on the Internet.

## Build and use Docker

1. Install [Git](https://git-scm.com/)
2. Clone this [repository](https://github.com/Chris82111/StardewValleyViaDocker)

```bash
clone https://github.com/Chris82111/StardewValleyViaDocker.git
```

3. Create an account on [GOG](https://www.gog.com/en/)
4. Buy [Stardew Valley](https://www.gog.com/de/game/stardew_valley)
5. Download the Linux version (the *.sh file) and place it in the `Dockerfile` file folder
6. Build the image:

```bash
docker build -t stardew_valley_via_docker_image .
```

7. Build the container. You must set the environment variable `SERVER_ENDPOINT=127.0.0.1` and replace the IP with the IP of our server. Optionally, you can expose more ports `-p 5901:5901` ([TigerVNC](https://tigervnc.org/)), `-p 6081:6081` ([noVNC](https://novnc.com/info.html)) or `-p 24642:24642/udp` ([Stardew Valley](https://www.gog.com/de/game/stardew_valley)). However, this is not necessary as the ports are accessible with an active [WireGuard](https://www.wireguard.com/) VPN connection, so use:

```bash
docker container create -it -p 51820:51820/udp -e SERVER_ENDPOINT=127.0.0.1 -e SERVER_PORT=51820 --cap-add=NET_ADMIN --cap-add=SYS_MODULE --mount type=bind,source="$(pwd)"/saves,target=/root/.config/StardewValley/Saves --mount type=bind,source="$(pwd)"/mods,target=/game/stardew_valley/data/noarch/game/Mods --mount type=bind,source="$(pwd)"/config,target=/config --mount type=bind,source="$(pwd)"/wireguard,target=/wireguard/certificates --name stardew_valley_via_docker_container stardew_valley_via_docker_image sh
```

8. Start the container:

```bash
docker container start stardew_valley_via_docker_container
```

## More

Stop the container:

```bash
docker container stop stardew_valley_via_docker_container
```

## Client

Each client must perform the following steps to establish a connection to the server:

1. Buy and install Stardew Valley on [GOG](https://www.gog.com/de/game/stardew_valley) or [Steam](https://store.steampowered.com/app/413150/Stardew_Valley/)
2. Install [WireGuard](https://www.wireguard.com/)
3. Set up WireGuard with one of the configuration files in the directory `wireguard` named `wg0_<n>.conf`
4. Connect to the game with `10.8.0.1:24642`

## Directories

1. `saves` Contains the game's save states. Save your game data before use.
2. `Mods` Contains the mods. Existing mods will not be replaced, the mods must be deleted manually for the update.
3. `config` You can change some settings, you must stop and start the container:
    1. Use `useGui` to enable and disable TigerVNC and noVNC. Note the CPU load: \
    550 % ± 50 % with GUI \
    135 % ±  5 % without GUI
    2. Use `wireguard.clients` to increase the number of wireguard certificates.
4. `wireguard` Contain the WireGuard certificates.
