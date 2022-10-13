#!/usr/bin/env bash
# shellcheck shell=bash
# - - - - - - - - - - - - - - - - - - - - - - - - - - - - - - - - - - -
##@Version           :  202210121546-git
# @@Author           :  Jason Hempstead
# @@Contact          :  jason@casjaysdev.com
# @@License          :  WTFPL
# @@ReadME           :  entrypoint-bun.sh --help
# @@Copyright        :  Copyright: (c) 2022 Jason Hempstead, Casjays Developments
# @@Created          :  Wednesday, Oct 12, 2022 15:46 EDT
# @@File             :  entrypoint-bun.sh
# @@Description      :
# @@Changelog        :  New script
# @@TODO             :  Better documentation
# @@Other            :
# @@Resource         :
# @@Terminal App     :  no
# @@sudo/root        :  no
# @@Template         :  other/docker-entrypoint
# - - - - - - - - - - - - - - - - - - - - - - - - - - - - - - - - - - -
# Set bash options
[ -n "$DEBUG" ] && set -x
# - - - - - - - - - - - - - - - - - - - - - - - - - - - - - - - - - - -
APPNAME="$(basename "$0" 2>/dev/null)"
VERSION="202210121546-git"
HOME="${USER_HOME:-$HOME}"
USER="${SUDO_USER:-$USER}"
RUN_USER="${SUDO_USER:-$USER}"
SCRIPT_SRC_DIR="${BASH_SOURCE%/*}"
# - - - - - - - - - - - - - - - - - - - - - - - - - - - - - - - - - - -
# Set functions
__find() { ls -A "$*" 2>/dev/null || return 10; }
# - - - - - - - - - - - - - - - - - - - - - - - - - - - - - - - - - - -
__exec_command() {
  local cmd="${*:-/bin/bash -l}"
  local exitCode=0
  echo "Executing command: $cmd"
  eval "$cmd" || exitCode=10
  [ "$exitCode" = 0 ] || exitCode=10
  return ${exitCode:-$?}
}
# - - - - - - - - - - - - - - - - - - - - - - - - - - - - - - - - - - -
# Functions
__heath_check() {
  local status=0
  #curl -q -LSsf -o /dev/null -s -w "200" "http://localhost/server-health" || status=$(($status + 1))
  echo "$(uname -s) $(uname -m) is running"
  return ${status:-$?}
}
# - - - - - - - - - - - - - - - - - - - - - - - - - - - - - - - - - - -
# Define default variables - don not change these
export TZ="${TZ:-America/New_York}"
export LOCAL_BIN_DIR="${LOCAL_BIN_DIR:-/usr/local/bin}"
export HOSTNAME="${HOSTNAME:-casjaysdev-bin}"
export SSL="${SSL:-false}"
export SSL_DIR="${SSL_DIR:-/config/ssl}"
export SSL_CA="${SSL_CA:-$SSL_DIR/ca.crt}"
export SSL_KEY="${SSL_KEY:-$SSL_DIR/server.key}"
export SSL_CERT="${SSL_CERT:-$SSL_DIR/server.crt}"
# - - - - - - - - - - - - - - - - - - - - - - - - - - - - - - - - - - -
# Additional variables and variable overrides
export HTTP_PORT="${HTTP_PORT:-80}"
export HTTPS_PORT="${HTTPS_PORT:-443}"
export SERVICE_PORT="${SERVICE_PORT:-}"
export DEFAULT_CONF_DIR="${DEFAULT_CONF_DIR:-/usr/local/share/template-files/config/defaults}"
# - - - - - - - - - - - - - - - - - - - - - - - - - - - - - - - - - - -
# import variables from file
[ -f "/root/env.sh" ] && . "/root/env.sh"
[ -f "/config/env.sh" ] && "/config/env.sh"
[ -f "/config/.env.sh" ] && . "/config/.env.sh"
# - - - - - - - - - - - - - - - - - - - - - - - - - - - - - - - - - - -
# Set timezone
[ -n "${TZ}" ] && echo "${TZ}" >"/etc/timezone"
[ -f "/usr/share/zoneinfo/${TZ}" ] && ln -sf "/usr/share/zoneinfo/${TZ}" "/etc/localtime"
# - - - - - - - - - - - - - - - - - - - - - - - - - - - - - - - - - - -
# Set hostname
if [ -n "${HOSTNAME}" ]; then
  echo "${HOSTNAME}" >"/etc/hostname"
  echo "127.0.0.1 ${HOSTNAME} localhost ${HOSTNAME}.local" >"/etc/hosts"
fi
# - - - - - - - - - - - - - - - - - - - - - - - - - - - - - - - - - - -
# Delete any gitkeep files
[ -d "/data" ] && rm -Rf "/data/.gitkeep" "/data"/*/*.gitkeep
[ -d "/config" ] && rm -Rf "/config/.gitkeep" "/data"/*/*.gitkeep
# - - - - - - - - - - - - - - - - - - - - - - - - - - - - - - - - - - -
# Setup bin directory
if [ -d "/config/bin" ]; then
  for bin in /config/bin/*; do
    name="$(basename "$bin")"
    ln -sf "$bin" "/usr/local/bin/$name"
  done
fi
# - - - - - - - - - - - - - - - - - - - - - - - - - - - - - - - - - - -
# Create directories
[ -d "/etc/ssl" ] || mkdir -p "/etc/ssl"
[ -d "/usr/local/bin" ] && rm -Rf "/usr/local/bin/.gitkeep"
# - - - - - - - - - - - - - - - - - - - - - - - - - - - - - - - - - - -
if [ "$SSL" = "true" ] || [ "$SSL" = "yes" ]; then
  if [ -f "/config/ssl/server.crt" ] && [ -f "/config/ssl/server.key" ]; then
    export SSL="true"
    if [ -n "$SSL_CA" ] && [ -f "$SSL_CA" ]; then
      mkdir -p "/etc/ssl/certs"
      cat "$SSL_CA" >>"/etc/ssl/certs/ca-certificates.crt"
    fi
  else
    [ -d "$SSL_DIR" ] || mkdir -p "$SSL_DIR"
    create-ssl-cert
  fi
  type update-ca-certificates &>/dev/null && update-ca-certificates
fi
# - - - - - - - - - - - - - - - - - - - - - - - - - - - - - - - - - - -
[ -f "$SSL_CA" ] && cp -Rfv "$SSL_CA" "/etc/ssl/ca.crt"
[ -f "$SSL_KEY" ] && cp -Rfv "$SSL_KEY" "/etc/ssl/server.key"
[ -f "$SSL_CERT" ] && cp -Rfv "$SSL_CERT" "/etc/ssl/server.crt"
# - - - - - - - - - - - - - - - - - - - - - - - - - - - - - - - - - - -
# Create default config
if [ ! -e "/config/$APPNAME" ] && [ -e "$DEFAULT_CONF_DIR/$APPNAME" ]; then
  cp -Rf "$DEFAULT_CONF_DIR/$APPNAME" "/config/$APPNAME"
fi
# - - - - - - - - - - - - - - - - - - - - - - - - - - - - - - - - - - -
# Setup bun
mkdir -p "/data/htdocs/www" && cd "/data/htdocs/www" || exit 10
if [ -z "$1" ] && [ -z "$(ls -A "/data/htdocs/www"/* 2>/dev/null)" ]; then
  cp -Rf "/usr/local/share/template-files/data/htdocs/www/." "/data/htdocs/www/"
fi
# - - - - - - - - - - - - - - - - - - - - - - - - - - - - - - - - - - -
# Additional commands

# - - - - - - - - - - - - - - - - - - - - - - - - - - - - - - - - - - -
case "$1" in
--help) # Help message
  echo 'Docker container for '$APPNAME''
  echo "Usage: $APPNAME [healthcheck, bash, command]"
  echo "Failed command will have exit code 10"
  echo ""
  exit ${exitCode:-$?}
  ;;

healthcheck) # Docker healthcheck
  __heath_check || exitCode=10
  exit ${exitCode:-$?}
  ;;

*/bin/sh | */bin/bash | bash | shell | sh) # Launch shell
  shift 1
  __exec_command "${@:-/bin/bash}"
  exit ${exitCode:-$?}
  ;;

bun)
  shift 1
  bun "$@"
  ;;

*) # Execute primary command
  if [ $# -eq 0 ]; then
    if [ -n "$RUN_SCRIPT" ]; then
      START_SCRIPT="$RUN_SCRIPT"
    elif [ -f "src/index.ts" ]; then
      RUN_SCRIPT="index.ts"
    elif [ -f "index.ts" ]; then
      RUN_SCRIPT="index.ts"
    elif [ -f "app.ts" ]; then
      RUN_SCRIPT="app.ts"
    elif [ -f "server.ts" ]; then
      RUN_SCRIPT="server.ts"
    fi
    echo "Running bun install"
    bun install
    echo "Running bun dev ${RUN_SCRIPT:-$START_SCRIPT}"
    bun dev ${RUN_SCRIPT:-$START_SCRIPT} || echo "Failed to run bun dev ${RUN_SCRIPT:-$START_SCRIPT}"
    exit ${exitCode:-$?}
  else
    __exec_command "$@"
    exitCode=$?
  fi
  ;;
esac
# - - - - - - - - - - - - - - - - - - - - - - - - - - - - - - - - - - -
# end of entrypoint
exit ${exitCode:-$?}
# - - - - - - - - - - - - - - - - - - - - - - - - - - - - - - - - - - -
