#!/bin/bash

#------------------------------------------------------------------------------
### Variables
#------------------------------------------------------------------------------

# Defined in Dockerfile
#TRUE="1"
#FALSE="0"
#
#VNC_PASSWORD
#VNC_PASSWORD_LENGTH
#VNC_ONLY_LOCALHOST
#RESOLUTION
#VNC_PASSWORD_FILE
#
#NOVNC_START
#NOVNC_APP_PATH
#NOVNC_LOGFILE
#NOVNC_PID_FILE


# -----------------------------------------------------------------------------
#   Colors, ANSI escape codes
# -----------------------------------------------------------------------------

# Change standard echo function
function echo() { builtin echo -e "$@"; }

# check if stdout is a terminal
if test -t 1; then

  # see if it supports colors
  ncolors=$(tput colors 2> /dev/null)

  # ANSI escape codes
  bold="\033[1m"
  underline="\033[4m"
  standout="\033[0m" 
  normal="\033[0m" 
  black="\033[30m"
  red="\033[31m"
  green="\033[32m"
  yellow="\033[1;33m"
  blue="\033[34m"
  magenta="\033[1;35m"
  cyan="\033[36m"
  white="\033[1;37m"
  
  # needs the -e switch in echo
  # \033[38;2;<r>;<g>;<b>m     #Select RGB foreground color
  # \033[48;2;<r>;<g>;<b>m     #Select RGB background color
fi


#------------------------------------------------------------------------------
###
#------------------------------------------------------------------------------

PASS="${green}pass${standout}"
FAIL="${red}fail${standout}"
HOSTNAME=$(hostname)

random_n () {
  echo "$(head -c 500 /dev/urandom | tr -dc 'a-zA-Z0-9~!@#$%^&*_-' | fold -w $1 | head -n 1)"
}

#------------------------------------------------------------------------------
###
#------------------------------------------------------------------------------

echo "${magenta}VNC_KILL_OPEN_VNCSERVERS:${standout}"

array=( $(ls /root/.vnc/*.pid 2> /dev/null) )
SPLIT="/root/.vnc/${HOSTNAME}"
for NO in "${array[@]}" ; do
  DISPLAYNUMBER=$(echo "${NO#*$SPLIT}" | sed 's/.pid//')
  echo "Kill vncserver ${DISPLAYNUMBER}"
  # Use command `tigervncserver` or use `vncserver` the same way
  vncserver -kill "$DISPLAYNUMBER"
done


echo "${magenta}VNC_SET_PASSWORD:${standout}"

if [ -z ${VNC_PASSWORD} ] ; then 
  export VNC_PASSWORD=$(random_n ${VNC_PASSWORD_LENGTH})
  echo "${VNC_PASSWORD}" > "${VNC_PASSWORD_FILE}"
fi

# Use command `tigervncpasswd` or use `vncpasswd` the same way
{ echo -e "${VNC_PASSWORD}\n${VNC_PASSWORD}\nn\n" | tigervncpasswd ; } > /dev/null 2>&1

if [ "$?" != "0" ] ; then
  echo "[$FAIL] Could not change password"
  exit 1
else
  echo "[$PASS] Could change password"
fi


#------------------------------------------------------------------------------
if [ "true" != "$(eval ${evalUseGui})" ] ; then
  echo "[$PASS] Use without GUI"
  echo "${magenta}VNC_START:${standout} skipped"
  echo "${magenta}NOVPN_START:${standout} skipped"
  exit 0
fi
#------------------------------------------------------------------------------


echo "${magenta}VNC_START:${standout}"

# Use command `tigervncserver` or use `vncserver` the same way
# [-localhost yes|no]    Only accept VNC connections from localhost
if [ "${TRUE}" = "${VNC_ONLY_LOCALHOST}" ] ; then
  OUTPUT="$(vncserver -localhost yes -geometry ${RESOLUTION} 2>&1 )"
else
  OUTPUT="$(vncserver -localhost no -geometry ${RESOLUTION} 2>&1 )"
fi

if [[ "$OUTPUT" == *"Log file is "* ]] ; then 
  SPLIT="Log file is "
  TMP="${OUTPUT#*$SPLIT}"
  FILE="${TMP%%.log*}"
  LOGFILE="${FILE}.log"
  PIDFILE="${FILE}.pid"
  PID="$(cat ${PIDFILE})"
  SPLIT="/root/.vnc/${HOSTNAME}"
  DISPLAYNUMBER=$(echo "${FILE#*$SPLIT}" )
  
  echo "resolution: ${RESOLUTION}"
  echo "log file  : ${LOGFILE}"
  echo "display   : ${DISPLAYNUMBER}"
  echo "pid       : ${PID}"
  echo "password  : ${VNC_PASSWORD}"
else
  echo "[$FAIL] Could not start vnc server"
  exit 1
fi

# Use command `tigervncserver` or use `vncserver` the same way
#tigervncserver -list 			 


#------------------------------------------------------------------------------
###
#------------------------------------------------------------------------------

echo "${magenta}NOVPN_START:${standout}"


if [ ! -z ${NOVNC_PID_FILE} ] ; then 
  NOVNC_PID="$(cat ${NOVNC_PID_FILE} 2>/dev/null)"
  kill -kill "${NOVNC_PID}" 2>/dev/null
  rm "${NOVNC_PID_FILE}" > /dev/null 2>&1
  NOVNC_PID=
fi

if [ "${TRUE}" = "${NOVNC_START}" ] ; then

  "${NOVNC_APP_PATH}/utils/novnc_proxy" --vnc localhost:5901 --listen 6081 > "${NOVNC_LOGFILE}" 2>&1 & NOVNC_PID=$!
  
  TIMEOUT_TIME="10"
  TIMEOUT="${FALSE}"
  TEST="${FALSE}"
  END_TIME=$(($(date +%s) + "${TIMEOUT_TIME}"))
  while [ "${FALSE}" = "${TEST}" ] && [ "${FALSE}" = "${TIMEOUT}" ] ; do
    { time sleep 0.1 ; } > "/dev/null" 2>&1
    if [ "${TRUE}" = "$( cat ${NOVNC_LOGFILE} | grep -A2 "Navigate to this URL:" > /dev/null 2>&1 && echo ${TRUE} || echo ${FALSE} )" ] ; then TEST="${TRUE}" ; fi 
    if [ $(date +%s) -gt $END_TIME ] ; then TIMEOUT="${TRUE}" ; fi
  done
  
  if [ "${FALSE}" = "${TIMEOUT}" ] ; then
    echo "[$PASS] Could noVNC be started in ${TIMEOUT_TIME} seconds?"
    
    echo "${NOVNC_PID}" > "${NOVNC_PID_FILE}"
    sed -i "s/${HOSTNAME}/localhost/g" "${NOVNC_LOGFILE}"
    NOVNC_LINK=$(cat ${NOVNC_LOGFILE} | grep -A2 "Navigate to this URL:" | grep . | grep -v 'Navigate to this URL:' | grep -o '[^$(printf '\t') ].*')
    
    echo "pid       : ${NOVNC_PID}"
    echo "pid file  : ${NOVNC_PID_FILE}"
    echo "log file  : ${NOVNC_LOGFILE}"
    echo "connect   : ${NOVNC_LINK}"
    echo "password  : ${VNC_PASSWORD}"
  else
    echo "[$FAIL] Could noVNC be started in ${TIMEOUT_TIME} seconds?"
    if [ ! -z ${NOVNC_PID} ] ; then kill -kill ${NOVNC_PID} ; fi
  fi
  
fi

echo "${magenta}NOVPN_STARTUP_END${standout}"


#------------------------------------------------------------------------------
### EOF
#------------------------------------------------------------------------------
