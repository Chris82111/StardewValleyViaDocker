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
