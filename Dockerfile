# syntax=docker/dockerfile:1

FROM ubuntu:20.04

STOPSIGNAL SIGTERM

ENV TRUE="1"
ENV FALSE="0"


#------------------------------------------------------------------------------
### vnc and novnc
#------------------------------------------------------------------------------

# - Connect via noVNC, Website 6081
# - Connect via Windows TigerVNC 5901
# Needs SSH
# - Connect via Putty, Xming to e.g. `gnome-calculator`
# - Connect via `ssh root@127.0.0.1 -L 9904:localhost:5901` and TigerVNC 9904 PW via logs 

# Ports application is listening on: `-p 6081:6081`

# VNC
EXPOSE 5901

# noVNC
EXPOSE 6081


#------------------------------------------------------------------------------

ENV DEBIAN_FRONTEND=noninteractive

RUN \
  apt update && apt -y upgrade && \
  apt install -y --no-install-recommends \
# Desctop environment
  xfce4 xfce4-goodies \
# Messaging system
  dbus-x11 \
# Low-resolution bitmapped fonts
  xfonts-base \
# VNC server
  tigervnc-standalone-server tigervnc-common \
  python3


#------------------------------------------------------------------------------

# At least 6 characters, leave blank for random password
ENV VNC_PASSWORD=

# Length of the random password
ENV VNC_PASSWORD_LENGTH=20

ENV VNC_ONLY_LOCALHOST="${FALSE}"

# Set display resolution
ENV RESOLUTION=1920x1080

# The password is saved in this file
ENV VNC_PASSWORD_FILE="/vnc/password"


#------------------------------------------------------------------------------

# You can deactivate noVNC and only use VNC
ENV NOVNC_START="${TRUE}"

ENV NOVNC_DOWNLOAD_PATH="/vnc/download"
ENV NOVNC_PATH="/vnc"
ENV NOVNC_APP_PATH="${NOVNC_PATH}/noVNC-1.4.0"
ENV NOVNC_LOGFILE="${NOVNC_PATH}/novnc.log"
ENV NOVNC_PID_FILE="${NOVNC_PATH}/novnc.pid"

WORKDIR "${NOVNC_DOWNLOAD_PATH}"

ADD --checksum=sha256:89b0354c94ad0b0c88092ec7a08e28086d3ed572f13660bac28d5470faaae9c1 \
  https://github.com/novnc/noVNC/archive/refs/tags/v1.4.0.tar.gz \
  v1.4.0.tar.gz
  
ADD --checksum=sha256:628dd586e80865cd775cc402b96cf75f4daa647b0fefdc31366d08b7753016be \
  https://github.com/novnc/websockify/archive/refs/tags/v0.11.0.tar.gz \
  v0.11.0.tar.gz

WORKDIR "${NOVNC_PATH}"

RUN mkdir -p "${NOVNC_APP_PATH}" && \
  tar -xvf "${NOVNC_DOWNLOAD_PATH}/v1.4.0.tar.gz" --strip 1 -C "${NOVNC_APP_PATH}" && \
  rm "${NOVNC_DOWNLOAD_PATH}/v1.4.0.tar.gz"

RUN mkdir -p "${NOVNC_APP_PATH}/utils/websockify" && \
  tar -xvf "${NOVNC_DOWNLOAD_PATH}/v0.11.0.tar.gz" --strip 1 -C "${NOVNC_APP_PATH}/utils/websockify" && \
  rm "${NOVNC_DOWNLOAD_PATH}/v0.11.0.tar.gz"

RUN ln -s "${NOVNC_APP_PATH}/vnc_lite.html" "${NOVNC_APP_PATH}/index.html"


#------------------------------------------------------------------------------

ADD startVnc.sh .
RUN chmod +x startVnc.sh

ENV startVnc="${NOVNC_PATH}/startVnc.sh"

ENV healthVnc='vncserver -list | grep ":1" > /dev/null ; if [ "0" != "$?" ] ; then exit 1 ; fi'


#------------------------------------------------------------------------------
### .Net
#------------------------------------------------------------------------------

# ASP.NET Core 6.0 Runtime (v6.0.30) - Linux x64 Binaries

WORKDIR "/usr/share/dotnet"

ADD --checksum=sha256:f03fdd09e114028a3e4751d7504280cbf1264ca72bf69aa87bc8489348b46e64 \
  https://download.visualstudio.microsoft.com/download/pr/c8c7ccb6-b0f8-4448-a542-ed153838cac3/f104b5cc6c11109c0b48e2bb8f5b6cef/aspnetcore-runtime-6.0.31-linux-x64.tar.gz \
  dotnet.tar.gz

RUN mkdir -p /usr/share/dotnet && \
  tar -zxf dotnet.tar.gz -C /usr/share/dotnet &&\
  rm dotnet.tar.gz &&\
  ln -s /usr/share/dotnet/dotnet /usr/bin/dotnet

ENV DOTNET_ROOT=/usr/bin/dotnet
ENV PATH=$PATH:$DOTNET_ROOT:$DOTNET_ROOT/tools

RUN dotnet --info > /dev/null 2>&1 ; if [ "0" != "$?" ] ; then exit 1 ; fi


#------------------------------------------------------------------------------
### StardewValley
#------------------------------------------------------------------------------

EXPOSE 24642/udp

# Mount point: `--mount type=bind,source="$(pwd)"/game_saves,target=/root/.config/StardewValley/Saves`
ENV STARDEW_VALLEY_SAVES_PATH="/root/.config/StardewValley/Saves"
VOLUME ["${STARDEW_VALLEY_SAVES_PATH}"]


#------------------------------------------------------------------------------

RUN apt update && apt install -y \
  unzip


#------------------------------------------------------------------------------

WORKDIR "/game/download"

ENV STARDEW_VALLEY_SH="/game/download/stardew_valley.sh"

ADD stardew_valley_1_6_8_24119_6732702600_72964.sh "${STARDEW_VALLEY_SH}"

ENV STARDEW_VALLEY_PATH="/game/stardew_valley"

RUN unzip "${STARDEW_VALLEY_SH}" -d "${STARDEW_VALLEY_PATH}" ; \
  rm "${STARDEW_VALLEY_SH}"

ENV STARDEW_VALLEY_ICON_NAME="stardew_valley.desktop"

Add "${STARDEW_VALLEY_ICON_NAME}" "${STARDEW_VALLEY_PATH}/${STARDEW_VALLEY_ICON_NAME}"
RUN chmod +x "${STARDEW_VALLEY_PATH}/${STARDEW_VALLEY_ICON_NAME}" && \
# Menu symbol
  ln "${STARDEW_VALLEY_PATH}/${STARDEW_VALLEY_ICON_NAME}" "/usr/share/applications/" && \
# Desktop symbol
  mkdir -p /root/Desktop/ && \
  ln "${STARDEW_VALLEY_PATH}/${STARDEW_VALLEY_ICON_NAME}" "/root/Desktop/" && \
# Autostart
  ln "${STARDEW_VALLEY_PATH}/${STARDEW_VALLEY_ICON_NAME}" "/etc/xdg/autostart/" 


#------------------------------------------------------------------------------

WORKDIR "/game/download"

ENV SMAPI_ZIP="/game/download/SMAPI.zip"

ADD --checksum=sha256:6a2299e6b5b8c396d1a48dca6ff19f01773b51211de66e97ac659dd3687f56f8 \
  https://github.com/Pathoschild/SMAPI/releases/download/4.0.8/SMAPI-4.0.8-installer.zip \
  "${SMAPI_ZIP}"

ENV SMAPI_PATH="/game/download/smapi"

RUN OUT="${SMAPI_PATH}" && \
  unzip "${SMAPI_ZIP}" -d "${OUT}" && \
  rm "${SMAPI_ZIP}" && \
  NO="$(ls -1q ${OUT} | wc -l)" && \
  if [ "1" = "$NO" ] ; then \
    NAME="$(ls -1q ${OUT})" && \
    mv "${OUT}/${NAME}/"* "${OUT}" && \
    rmdir "${OUT}/${NAME}" ; \
  fi

# SMAPI, manual install 1
RUN mv "${SMAPI_PATH}/internal/linux/install.dat" "${SMAPI_PATH}/internal/linux/install.zip"

ENV SMAPI_INTERNAL_PATH="/game/download/smapi_internal"

RUN unzip "${SMAPI_PATH}/internal/linux/install.zip" -d "${SMAPI_INTERNAL_PATH}" && \
  rm -rf "${SMAPI_PATH}"

ENV STARDEW_VALLEY_GAME_PATH="${STARDEW_VALLEY_PATH}/data/noarch/game/"

# SMAPI, manual install 2
RUN mv "${SMAPI_INTERNAL_PATH}/"* "${STARDEW_VALLEY_GAME_PATH}" && \
  rmdir "${SMAPI_INTERNAL_PATH}"

# SMAPI, manual install 3
RUN cp "${STARDEW_VALLEY_GAME_PATH}/Stardew Valley.deps.json" "${STARDEW_VALLEY_GAME_PATH}/StardewModdingAPI.deps.json" 

# SMAPI, manual install 4
RUN mv "${STARDEW_VALLEY_GAME_PATH}/StardewValley" "${STARDEW_VALLEY_GAME_PATH}/StardewValley-original"

RUN mv "${STARDEW_VALLEY_GAME_PATH}/StardewModdingAPI" "${STARDEW_VALLEY_GAME_PATH}/StardewValley" 


#------------------------------------------------------------------------------

WORKDIR "/game/download"

ENV DEDICATED_SERVER_ZIP="/game/download/DedicatedServer.zip"

#ADD --checksum=sha256:33fe506f8f8c8020305baa6a17a35a9d9afb7aa1685ad7f8b5ba87b4e909936c \
#  https://github.com/Chris82111/SMAPIDedicatedServerMod/releases/download/v1.0.2-beta2/DedicatedServer.1.0.2.beta2.zip \
#  "${DEDICATED_SERVER_ZIP}"

ADD --checksum=sha256:88bb3f5ad6a0afd4b7e9d691152cdb706070c2418562bb6f92cb92970485486d \
  https://github.com/Chris82111/SMAPIDedicatedServerMod/releases/download/v1.1.0-beta/DedicatedServer.1.1.0.zip \
  "${DEDICATED_SERVER_ZIP}"

ENV DEDICATED_SERVER_PATH="/game/download/dedicated_server"

RUN OUT="${DEDICATED_SERVER_PATH}" && \
  unzip "${DEDICATED_SERVER_ZIP}" -d "${OUT}" && \
  rm "${DEDICATED_SERVER_ZIP}" && \
  NO="$(ls -1q ${OUT} | wc -l)" && \
  if [ "1" = "$NO" ] ; then \
    NAME="$(ls -1q ${OUT})" && \
    mv "${OUT}/${NAME}/"* "${OUT}" && \
    rmdir "${OUT}/${NAME}" ; \
  fi
  
RUN mv "${DEDICATED_SERVER_PATH}"* "${STARDEW_VALLEY_GAME_PATH}/Mods/DedicatedServer"


#------------------------------------------------------------------------------
###
#------------------------------------------------------------------------------

# Use `kill -s TERM 1` from inside to send SIGTERM and to shutdown the container

ENV red="\033[0;31m"
ENV green="\033[0;32m"
ENV yellow="\033[0;33m"
ENV normal="\033[0;00m"

ENV textApplicationStarted="${green}Application is started.${normal}"
ENV textApplicationNotStarted="${red}Unexpected Error, container is exited.${normal}"
ENV textObservedPidCanceled="${yellow}One observed PID was canceled, testing...${normal}"
ENV textApplicationStopedNormal="${green}Application executed, container is shut down.${normal}"
ENV textApplicationError="${red}Daemon failed.${normal}"
ENV textApplicationStopedSuddenly="${yellow}Application was suddenly shut down.${normal}"

# Shows whether the TERM signal was received
ENV termSignalReceived="${FALSE}"

# If one observed PID fails it waits for this time to shutdown the container.
ENV timeoutWaitPidTime=10

WORKDIR "/app"

### example
#ENV startExample='/ssh/startBg.sh & PID_EX=$!'
#ENV stopExample='kill -TERM ${PID_EX} ; wait ${PID_EX}'

#HEALTHCHECK NONE
HEALTHCHECK --interval=30s --timeout=1s --retries=1 --start-period=0 CMD /bin/sh -c "\
# --> insert health check
	eval $healthVnc \
# <-- end health check
  "

ENV sigTermHandler='\
  echo -e "${yellow}SIGTERM has been received, container will shut down.${normal}" ; \
  termSignalReceived="${TRUE}" ; \
# --> insert stop
# eval $stopExample ; \
# <-- end stop
  '

ENV startBehavior='\
  trap "${sigTermHandler}" TERM && \
# --> insert start
# eval $startExample && \
  eval $startSsh && \
  eval $startVnc && \
# <-- end start
  echo -e $textApplicationStarted || \
  { echo -e $textApplicationNotStarted ; exit 1 ; } ; \
  sleep infinity & PID=$! ; \
# --: Enter all PIDs you want to observ, terminating a pid leads to the container being shut down
  wait -n ${PID} ; \
  echo -e $textObservedPidCanceled ; \
    function timeoutWaitPid { \
      TIMEOUT="${FALSE}" ; END_TIME="$(( $(date +%s) + ${timeoutWaitPidTime} ))" ; \
      while [ "${FALSE}" = "${termSignalReceived}" ] && [ "${FALSE}" = "${TIMEOUT}" ] ; do \
        { time sleep 0.1 ; } > /dev/null 2>&1 ; \
        if [ $(date +%s) -gt $END_TIME ] ; then TIMEOUT="${TRUE}" ; fi ; \
      done ; \
      if [ "${TRUE}" = "${TIMEOUT}" ] ; then return 1 ; else return 0 ; fi ; } ; \
  timeoutWaitPid && \
  { pkill -TERM -P $$ ; wait ; echo -e $textApplicationStopedNormal ; } || \
  { echo -e $textApplicationError ; pkill -TERM -P $$ ; wait ; echo -e $textApplicationStopedSuddenly ; } \
  '

ENTRYPOINT ["/bin/bash", "-c" , "eval $startBehavior"]


#------------------------------------------------------------------------------
###
#------------------------------------------------------------------------------
