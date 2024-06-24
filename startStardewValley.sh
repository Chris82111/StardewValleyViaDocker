#!/bin/bash

#------------------------------------------------------------------------------
### Variables
#------------------------------------------------------------------------------

# Defined in Dockerfile
#TRUE="1"
#FALSE="0"


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

echo "${magenta}STARDEW_VALLEY_START${standout}"

echo "Copy      : Mod files"
cp -an "${STARDEW_VALLEY_GAME_PATH}/ModsCopy/." "${STARDEW_VALLEY_GAME_PATH}/Mods"

if [ "true" == "$(eval ${evalUseGui})" ] ; then
  # GUI 550 % to 600 % of my CPU
  echo "Start     : with GUI"
  export DISPLAY=:1
  xdg-open "${STARDEW_VALLEY_PATH}/${STARDEW_VALLEY_ICON_NAME}" & PID_SW=$!
  # Nice to know, an autostart can be realized by a desktop icon file in the autostart directory.
  # ln "${STARDEW_VALLEY_PATH}/${STARDEW_VALLEY_ICON_NAME}" "/etc/xdg/autostart/" 
else
  # Without GUI 140 % but VNC is running, 130 % without VNC
  echo "Start     : without GUI"
  rm -f "${STARDEW_VALLEY_PATH}/stdin.pipe"
  mkfifo "${STARDEW_VALLEY_PATH}/stdin.pipe"
  sleep infinity > "${STARDEW_VALLEY_PATH}/stdin.pipe" &
  xvfb-run "${STARDEW_VALLEY_PATH}/data/noarch/start.sh" < "${STARDEW_VALLEY_PATH}/stdin.pipe" &
  PID_SW=$!
fi


echo "${magenta}STARDEW_VALLEY_END${standout}"

exit 0


#------------------------------------------------------------------------------
### EOF
#------------------------------------------------------------------------------
