# Stardew Valles

```shell
  docker kill vnc_base_container ; docker rm vnc_base_container ; docker build -t vnc_base_image . ; docker container create -it -p 6081:6081 -p 24642:24642/udp --mount type=bind,source="$(pwd)"/game_saves,target=/root/.config/StardewValley/Saves --cpus="1" --name vnc_base_container vnc_base_image sh ; docker container start vnc_base_container ; docker exec -ti vnc_base_container /bin/bash
```
