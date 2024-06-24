# Stardew Valles

```shell
  docker kill vnc_base_container ; docker rm vnc_base_container ; docker build -t vnc_base_image . ; docker container create -it -p 5901:5901 -p 6081:6081 -p 24642:24642/udp --mount type=bind,source=c:/temp/game_saves,target=/root/.config/StardewValley/Saves --mount type=bind,source=c:/temp/game_mods,target=/game/stardew_valley/data/noarch/game/Mods --mount type=bind,source=c:/temp/config,target=/config --name vnc_base_container vnc_base_image sh ; docker container start vnc_base_container ; docker exec -ti vnc_base_container /bin/bash
```
