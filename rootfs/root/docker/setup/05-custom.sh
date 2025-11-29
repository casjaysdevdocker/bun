#!/usr/bin/env bash
# - - - - - - - - - - - - - - - - - - - - - - - - - - - - - - - - - - -
##@Version           :  202511291200-git
# @@Author           :  CasjaysDev
# @@Contact          :  CasjaysDev <docker-admin@casjaysdev.pro>
# @@License          :  MIT
# @@ReadME           :
# @@Copyright        :  Copyright 2023 CasjaysDev
# @@Created          :  Mon Aug 28 06:48:42 PM EDT 2023
# @@File             :  05-custom.sh
# @@Description      :  script to install Bun
# - - - - - - - - - - - - - - - - - - - - - - - - - - - - - - - - - - -
# shellcheck shell=bash
# shellcheck disable=SC2016
# shellcheck disable=SC2031
# shellcheck disable=SC2120
# shellcheck disable=SC2155
# shellcheck disable=SC2199
# shellcheck disable=SC2317
# - - - - - - - - - - - - - - - - - - - - - - - - - - - - - - - - - - -
# Set bash options
set -o pipefail
[ "$DEBUGGER" = "on" ] && echo "Enabling debugging" && set -x$DEBUGGER_OPTIONS
# - - - - - - - - - - - - - - - - - - - - - - - - - - - - - - - - - - -
# Set env variables
exitCode=0
LANG_VERSION="${LANG_VERSION:-latest}"

# - - - - - - - - - - - - - - - - - - - - - - - - - - - - - - - - - - -
# Predefined actions
echo "Installing Bun version: ${LANG_VERSION}"

# Install Bun
if [ "$LANG_VERSION" = "latest" ]; then
  echo "Installing latest Bun..."
  curl -fsSL https://bun.sh/install | bash || exitCode=1
else
  echo "Installing Bun v${LANG_VERSION}..."
  curl -fsSL https://bun.sh/install | bash -s "bun-v${LANG_VERSION}" || exitCode=1
fi

# Move to /usr/local/bin
if [ -f "$HOME/.bun/bin/bun" ]; then
  mv "$HOME/.bun/bin/bun" /usr/local/bin/bun || exitCode=1
  mv "$HOME/.bun/bin/bunx" /usr/local/bin/bunx || exitCode=1
  rm -rf "$HOME/.bun"
  echo "Bun installed successfully"
  bun --version || exitCode=1
else
  echo "Bun installation failed" >&2
  exitCode=1
fi

# - - - - - - - - - - - - - - - - - - - - - - - - - - - - - - - - - - -
# Set the exit code
exit $exitCode
# - - - - - - - - - - - - - - - - - - - - - - - - - - - - - - - - - - -
# ex: ts=2 sw=2 et filetype=sh
