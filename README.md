# Stardew Valley via Docker

<div align="center">

[![Stardew Valley 1.6.8](https://img.shields.io/badge/Stardew_Valley-1.6.8-153C86)](https://www.stardewvalley.net/ "Link to Stardew Valley")
[![SMAPI 4.0.8](https://img.shields.io/badge/SMAPI-4.0.8-5cb811)](https://smapi.io/ "Link to SMAPI")
[![SMAPIDedicatedServerMod](https://img.shields.io/badge/Mod-v1.1.3--beta-blue)](https://github.com/Chris82111/SMAPIDedicatedServerMod/releases/tag/v1.1.3-beta "Link to Mod Download")
[![Mod Description](https://img.shields.io/badge/Description-v1.1.3--beta-blue)](https://github.com/Chris82111/SMAPIDedicatedServerMod/tree/v1.1.3-beta "Link to Mod Description")

</div>

With this repository you can run Stardew Valley as a multiplayer server in a Docker container. [Stardew Valley](https://www.gog.com/de/game/stardew_valley), [SMAPI](https://smapi.io/), the multiplayer mod [SMAPIDedicatedServerMod](https://github.com/ObjectManagerManager/SMAPIDedicatedServerMod) and all server applications are installed automatically. The server is hidden behind a VPN connection. Each client must connect to the server with [WireGuard](https://www.wireguard.com/). In the directory `wireguard` you will find the necessary WireGuard certificates. After someone is connected, it is possible to use Stardew Valley ([GOG](https://www.gog.com/de/game/stardew_valley), [Steam](https://store.steampowered.com/app/413150/Stardew_Valley/)), [TigerVNC](https://tigervnc.org/) and [noVNC](https://novnc.com/info.html). To use the applications on the server, you must run WireGuard VPN and connect with the internal VPN IP address `10.8.0.1` and the correct port. With the connection you can only access the container, you cannot access anything on the server or on the Internet.

## Table of Contents

1. [Build and use Docker](#build-and-use-docker)
2. [Update](#update)
3. [More Commands](#more-commands)
4. [Client](#client)
5. [TigerVNC and noVNC](#tigervnc-and-novnc)
6. [Directories](#directories)

## Build and use Docker

1. Install [Git](https://git-scm.com/)
2. Clone this [repository](https://github.com/Chris82111/StardewValleyViaDocker)

    ```bash
    clone https://github.com/Chris82111/StardewValleyViaDocker.git
    ```

3. Create an account on [GOG](https://www.gog.com/en/)
4. Buy [Stardew Valley](https://www.gog.com/de/game/stardew_valley)
5. Download the Linux version (the *.sh file) and place it in the `Dockerfile` file folder
6. Switch to the repository:

    ```bash
    cd StardewValleyViaDocker
    ```

7. Build the image:

    ```bash
    docker build -t stardew_valley_via_docker_image .
    ```

8. Create the binding folders, sometimes this has to be done manually:

    ```bash
    mkdir "$(pwd)"/saves "$(pwd)"/mods "$(pwd)"/config "$(pwd)"/wireguard
    ```

9. Determine your server/public IP address.

10. Build the container.

    - You must set the environment variable `SERVER_ENDPOINT=127.0.0.1` and replace the IP with the IP of our server.
    - Optionally:
        - The option `--restart always` is set, but can be omitted or changed as required.
        - The CPU usage is limited with `--cpus=0.5`, but can be changed.
        - A VNC password is set with `-e VNC_PASSWORD=123456`. This is secure because it can only be used with an active VPN. If the option is not specified, the password is created randomly.
        - More ports can be exposed
            - `-p 5901:5901` ([TigerVNC](https://tigervnc.org/)),
            - `-p 6081:6081` ([noVNC](https://novnc.com/info.html)) or
            - `-p 24642:24642/udp` ([Stardew Valley](https://www.gog.com/de/game/stardew_valley)).
            - However, this is not necessary as the ports are accessible with an active [WireGuard](https://www.wireguard.com/) VPN connection. Forwarding the ports bypasses the VPN connection and weakens the protection.
    - Normally use:

    ```bash
    docker container create -it --restart always --cpus=0.5 -e VNC_PASSWORD=123456 -p 51820:51820/udp -e SERVER_ENDPOINT=127.0.0.1 -e SERVER_PORT=51820 --cap-add=NET_ADMIN --cap-add=SYS_MODULE --mount type=bind,source="$(pwd)"/saves,target=/root/.config/StardewValley/Saves --mount type=bind,source="$(pwd)"/mods,target=/game/stardew_valley/data/noarch/game/Mods --mount type=bind,source="$(pwd)"/config,target=/config --mount type=bind,source="$(pwd)"/wireguard,target=/wireguard/certificates --name stardew_valley_via_docker_container stardew_valley_via_docker_image sh
    ```

11. Start the container:

    ```bash
    docker container start stardew_valley_via_docker_container
    ```

12. Forward port:

On the server, you only need to forward the WireGuard port 51820.

## Update

:information_source: Back up your game data first. \
:information_source: The old files/mods in the mounted directories must be deleted manually before starting the upgrade.

## More Commands

View logs:

```bash
docker logs stardew_valley_via_docker_container
```

View resources used by your containers:

```bash
docker stats stardew_valley_via_docker_container
```

Stop the container:

```bash
docker container stop stardew_valley_via_docker_container
```

Remove old container:

```bash
docker rm stardew_valley_via_docker_container
```

Linux command to see your current server load, public IP

```bash
landscape-sysinfo
```

## Client

Each client must perform the following steps to establish a connection to the server:

1. Buy and install Stardew Valley on [GOG](https://www.gog.com/de/game/stardew_valley) or [Steam](https://store.steampowered.com/app/413150/Stardew_Valley/)
2. Install [WireGuard](https://www.wireguard.com/)
3. Set up WireGuard with one of the configuration files in the directory `wireguard` named `wg0_<n>.conf`
4. Connect to the game with `10.8.0.1:24642`

## TigerVNC and noVNC

[TigerVNC](https://tigervnc.org/) or [noVNC](https://novnc.com/info.html) can be used to connect to the host's GUI. This makes it possible to solve problems. Due to the high CPU load and a delay of 1 second, it is not recommended to use this solution for gaming.

To use TigerVNC or noVNC, proceed as follows:

1. Go to the `config` folder and open the file `docker.json`.
2. Change the entry `useGui` to `true` and save the file
3. Stop and start the server
4. Use the command `logs` to find the password
5. Connect to the GUI...
    1. ...with a web browser (via noVNC), enter `http://10.8.0.1:6081/`
    2. ...with TigerVNC, connect to `10.8.0.1:5901`

> [!NOTE]
> Note the CPU load: \
> 550 % ± 50 % with GUI \
> 135 % ±  5 % without GUI \
> One solution may be to use `--cpus=1.5`, this should work, but try it yourself.

## Directories

1. `saves` Contains the game's save states. Save your game data before use.
2. `Mods` Contains the mods. Existing mods will not be replaced, the mods must be deleted manually for the update.
3. `config` You can change some settings, you must stop and start the container:
    1. Use `useGui` to enable and disable TigerVNC and noVNC. [Note the CPU load](#tigervnc-and-novnc)
    2. Use `wireguard.clients` to increase the number of wireguard certificates.
4. `wireguard` Contain the WireGuard certificates.
