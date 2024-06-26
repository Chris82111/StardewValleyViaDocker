#!/bin/bash

#------------------------------------------------------------------------------
### Variables
#------------------------------------------------------------------------------

# Defined in Dockerfile
#WIREGUARD_SERVER_CERTIFICATES_PATH
#WIREGUARD_CERTIFICATES_PATH
#
#INTERFACE="wg0"
#SERVER_ENDPOINT=127.0.0.1
#SERVER_PORT=51820
#
#SERVER_IP=10.8.0.1
#SERVER_IP_PREFIX=24
#
#CLIENT_IP=10.8.0
#CLIENT_IP_PREFIX=24
#


SERVER_DIR="${WIREGUARD_SERVER_CERTIFICATES_PATH}"
CLIENT_DIR="${WIREGUARD_CERTIFICATES_PATH}"

SERVER_PRIVATE_KEY="${SERVER_DIR}/private.key"
SERVER_PUBLIC_KEY="${SERVER_DIR}/public.key"
SERVER_CONFIG="${SERVER_DIR}/${INTERFACE}.conf"

PRESHARED_KEY="${SERVER_DIR}/presharedkey.key"

CLIENT_PRIVATE="${CLIENT_DIR}/private"
CLIENT_PUBLIC="${CLIENT_DIR}/public"
CLINET_KEY_EXTENSION="key"
CLIENT_CONFIG="${CLIENT_DIR}/${INTERFACE}"
CLIENT_CONFIG_EXTENSION="conf"
CLINET_COUNT_KEYS="$(eval ${evalWireguardClients})"


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
### Create keys
#------------------------------------------------------------------------------

RENEW_CONFIG="${FAIL}"

echo "${magenta}WIREGUARD_CREATE_KEYS:${standout}"

#------------------------------------------------------------------------------
# Preshared key
mkdir -p "${SERVER_DIR}"

if [ ! -f "${PRESHARED_KEY}" ]; then
  wg genpsk > "${PRESHARED_KEY}"
  RENEW_CONFIG="${TRUE}"
fi


#------------------------------------------------------------------------------
# Server private
if [ ! -f "${SERVER_PRIVATE_KEY}" ]; then
  wg genkey | tee "${SERVER_PRIVATE_KEY}" > /dev/null
  RENEW_CONFIG="${TRUE}"
fi


#------------------------------------------------------------------------------
# Server public
if [ "${SERVER_PRIVATE_KEY}" -nt "${SERVER_PUBLIC_KEY}" ]; then
  cat "${SERVER_PRIVATE_KEY}" | wg pubkey | tee "${SERVER_PUBLIC_KEY}" > /dev/null
  RENEW_CONFIG="${TRUE}"
fi


mkdir -p "${CLIENT_DIR}"

for (( i=1; i<=${CLINET_COUNT_KEYS}; i++ )) ; do
 
  CLIENT_PRIVATE_N="${CLIENT_PRIVATE}${i}.${CLINET_KEY_EXTENSION}"
  CLIENT_PUBLIC_N="${CLIENT_PUBLIC}${i}.${CLINET_KEY_EXTENSION}"

  #----------------------------------------------------------------------------
  # Client private
  if [ ! -f "${CLIENT_PRIVATE_N}" ]; then
    wg genkey | tee "${CLIENT_PRIVATE_N}" > /dev/null
    RENEW_CONFIG="${TRUE}"
  fi
  
  
  #----------------------------------------------------------------------------
  # Client public
  if [ "${CLIENT_PRIVATE_N}" -nt "${CLIENT_PUBLIC_N}" ]; then
    cat "${CLIENT_PRIVATE_N}" | wg pubkey | tee "${CLIENT_PUBLIC_N}" > /dev/null
    RENEW_CONFIG="${TRUE}"
  fi
  
done


#------------------------------------------------------------------------------
# Check whether configuration files are available
if [ ! -f "${SERVER_CONFIG}" ]; then
  RENEW_CONFIG="${TRUE}"
fi

for (( i=1; i<=${CLINET_COUNT_KEYS}; i++ )) ; do
  CLIENT="${CLIENT_CONFIG}_${i}.${CLIENT_CONFIG_EXTENSION}"
  if [ ! -f "${CLIENT}" ]; then
    RENEW_CONFIG="${TRUE}"
  fi
done


if [ "${RENEW_CONFIG}" = "$TRUE" ]; then

  #----------------------------------------------------------------------------
  # Create Server config file
  rm "${SERVER_CONFIG}" > /dev/null 2>&1
  touch "${SERVER_CONFIG}"
  echo "[Interface]" >> "${SERVER_CONFIG}"
  echo "Address = ${SERVER_IP}/${SERVER_IP_PREFIX}" >> "${SERVER_CONFIG}"
  echo "ListenPort = ${SERVER_PORT}" >> "${SERVER_CONFIG}"
  echo "PrivateKey = $(cat ${SERVER_PRIVATE_KEY})" >> "${SERVER_CONFIG}"

  for (( i=1; i<=${CLINET_COUNT_KEYS}; i++ )) ; do
  
    CLIENT_PUBLIC_N="${CLIENT_PUBLIC}${i}.${CLINET_KEY_EXTENSION}"
    IP="${CLIENT_IP}.$((i+1))"   
    echo "" >> "${SERVER_CONFIG}"
    echo "[Peer]" >> "${SERVER_CONFIG}"
    echo "PublicKey = $(cat ${CLIENT_PUBLIC_N})" >> "${SERVER_CONFIG}"
    echo "PresharedKey = $(cat ${PRESHARED_KEY})" >> "${SERVER_CONFIG}"
    echo "AllowedIPs = ${IP}/32" >> "${SERVER_CONFIG}"
  done


  #----------------------------------------------------------------------------
  # Create Client config files
  for (( i=1; i<=${CLINET_COUNT_KEYS}; i++ )) ; do
    CLIENT="${CLIENT_CONFIG}_${i}.${CLIENT_CONFIG_EXTENSION}"
    IP="${CLIENT_IP}.$((i+1))"  
    CLIENT_PRIVATE_N="${CLIENT_PRIVATE}${i}.${CLINET_KEY_EXTENSION}"
    
    rm "${CLIENT}" > /dev/null 2>&1
    touch "${CLIENT}"
    
    echo "[Interface]" >> "${CLIENT}"
    echo "Address = ${IP}/${CLIENT_IP_PREFIX}" >> "${CLIENT}"
    echo "PrivateKey = $(cat "${CLIENT_PRIVATE_N}")" >> "${CLIENT}"
    echo "" >> "${CLIENT}"
    echo "[Peer]" >> "${CLIENT}"
    echo "PublicKey = $(cat ${SERVER_PUBLIC_KEY})" >> "${CLIENT}"
    echo "PresharedKey = $(cat ${PRESHARED_KEY})" >> "${CLIENT}"
    echo "Endpoint = ${SERVER_ENDPOINT}:${SERVER_PORT}" >> "${CLIENT}"
    echo "AllowedIPs = ${SERVER_IP}/32" >> "${CLIENT}"
  
  done

fi


# Only root can access the key file
find "${SERVER_DIR}/" -type f -exec chmod 700 {} \;


#------------------------------------------------------------------------------
### Start apps
#------------------------------------------------------------------------------

# You can use nginx for testing <IP>:80, install `nginx`
if [ "${TRUE}" = "$(nginx -v > /dev/null 2>&1 && echo ${TRUE} || echo ${FALSE})" ] ; then
  echo "${magenta}WIREGUARD_START_NGINX:${standout}"
  service nginx start
fi


echo "${magenta}WIREGUARD_START:${standout}"
wg-quick down "${SERVER_DIR}/${INTERFACE}.conf" 2> /dev/null
wg-quick up "${SERVER_DIR}/${INTERFACE}.conf"


#------------------------------------------------------------------------------
### Test
#------------------------------------------------------------------------------

PASS="${green}pass${standout}"
FAIL="${red}fail${standout}"
ERROR="${FAIL}"

TEST_PORT=$(wg show "${INTERFACE}" | grep 'listening port:' | sed 's/^.*: //')

echo "${magenta}WIREGUARD_TESTS:${standout}"

if [ "${SERVER_PORT}" = "${TEST_PORT}" ]; then
  echo "[$PASS] wireguard uses the port you have specified?"
else
  echo "[$FAIL] wireguard uses the port you have specified?"
  ERROR="${TRUE}"
fi

echo -n "[" ;
netstat -nul | grep -q "0.0.0.0:${TEST_PORT}" && echo -n "$PASS" || { echo -n "$FAIL" ; ERROR="${TRUE}" ; } ;
echo "] Something is listening on ${TEST_PORT}?"

echo -n "[" ;
ifconfig | grep -A1 -q "${INTERFACE}" && echo -n "$PASS" || { echo -n "$FAIL" ; ERROR="${TRUE}" ; } ;
echo "] Network adapter is added?"

echo -n "[" ;
wg | grep -q "interface: ${INTERFACE}" && echo -n "$PASS" || { echo -n "$FAIL" ; ERROR="${TRUE}" ; } ;
echo "] Interface ${INTERFACE} is up?"

if [ "${ERROR}" = "$TRUE" ]; then
  exit 1;
fi

echo "${magenta}WIREGUARD_STARTUP_END:${standout}"

exit 0;


#------------------------------------------------------------------------------
### EOF
#------------------------------------------------------------------------------
