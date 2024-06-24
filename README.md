# Stardew Valles

```shell
  docker kill vnc_base_container ; docker rm vnc_base_container ; docker build -t vnc_base_image . ; docker container create -it -p 5901:5901 -p 6081:6081 -p 24642:24642/udp -p 51820:51820/udp --cap-add=NET_ADMIN --cap-add=SYS_MODULE --mount type=bind,source=c:/temp/game_saves,target=/root/.config/StardewValley/Saves --mount type=bind,source=c:/temp/game_mods,target=/game/stardew_valley/data/noarch/game/Mods --mount type=bind,source=c:/temp/config,target=/config --mount type=bind,source=c:/temp/wireguard_certificates,target=/wireguard/certificates --name vnc_base_container vnc_base_image sh ; docker container start vnc_base_container ; docker exec -ti vnc_base_container /bin/bash
```

CPU usage:
550 % +- 50 % with GUI
135 % +-  5 % without GUI