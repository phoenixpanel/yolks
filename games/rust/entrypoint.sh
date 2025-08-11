#!/bin/bash
set -euo pipefail

#
# Copyright (c) 2021 Phoenix Panel
#
# Permission is hereby granted, free of charge, to any person obtaining a copy
# of this software and associated documentation files (the "Software"), to deal
# in the Software without restriction, including without limitation the rights
# to use, copy, modify, merge, publish, distribute, sublicense, and/or sell
# copies of the Software, and to permit persons to whom the Software is
# furnished to do so, subject to the following conditions:
#
# The above copyright notice and this permission notice shall be included in all
# copies or substantial portions of the Software.
#
# THE SOFTWARE IS PROVIDED "AS IS", WITHOUT WARRANTY OF ANY KIND, EXPRESS OR
# IMPLIED, INCLUDING BUT NOT LIMITED TO THE WARRANTIES OF MERCHANTABILITY,
# FITNESS FOR A PARTICULAR PURPOSE AND NONINFRINGEMENT. IN NO EVENT SHALL THE
# AUTHORS OR COPYRIGHT HOLDERS BE LIABLE FOR ANY CLAIM, DAMAGES OR OTHER
# LIABILITY, WHETHER IN AN ACTION OF CONTRACT, TORT OR OTHERWISE, ARISING FROM,
# OUT OF OR IN CONNECTION WITH THE SOFTWARE OR THE USE OR OTHER DEALINGS IN THE
# SOFTWARE.
#

# Signal handler for graceful shutdown
shutdown_handler() {
    echo "Received shutdown signal, stopping server gracefully..."
    kill -TERM "$child" 2>/dev/null || true
    wait "$child"
    exit 0
}
trap shutdown_handler SIGTERM SIGINT

# Default the TZ environment variable to UTC
TZ=${TZ:-UTC}
export TZ

# Switch to the container's working directory
cd /home/container || {
    echo "ERROR: Failed to change to /home/container directory"
    exit 1
}

# Set environment variable that holds the Internal Docker IP
if command -v ip >/dev/null 2>&1; then
    INTERNAL_IP=$(ip route get 1 2>/dev/null | awk '{print $(NF-2);exit}' || echo "127.0.0.1")
else
    INTERNAL_IP="127.0.0.1"
fi
export INTERNAL_IP

# Auto-update game server if AUTO_UPDATE is not set or set to 1
if [[ -z "${AUTO_UPDATE:-}" ]] || [[ "${AUTO_UPDATE}" == "1" ]]; then
    printf "\033[1m\033[33mcontainer@phoenix~ \033[0mUpdating Rust server...\n"
    if [[ -f "./steamcmd/steamcmd.sh" ]]; then
        ./steamcmd/steamcmd.sh +force_install_dir /home/container +login anonymous +app_update 258550 +quit
    else
        echo "WARNING: SteamCMD not found, skipping auto-update"
    fi
else
    printf "\033[1m\033[33mcontainer@phoenix~ \033[0mSkipping auto-update (AUTO_UPDATE=${AUTO_UPDATE})\n"
fi

# Validate STARTUP variable exists
if [[ -z "${STARTUP:-}" ]]; then
    echo "ERROR: STARTUP variable is not set"
    exit 1
fi

# Replace Startup Variables
PARSED=$(echo "${STARTUP}" | sed -e 's/{{/${/g' -e 's/}}/}/g')
PARSED=$(eval echo "\"${PARSED}\"")

# Framework-specific setup
if [[ "${FRAMEWORK:-}" == "carbon" ]]; then
    printf "\033[1m\033[33mcontainer@phoenix~ \033[0mSetting up Carbon framework...\n"
    if curl -sSL "https://github.com/CarbonCommunity/Carbon.Core/releases/download/production_build/Carbon.Linux.Release.tar.gz" | tar zx; then
        export DOORSTOP_ENABLED=1
        export DOORSTOP_TARGET_ASSEMBLY="$(pwd)/carbon/managed/Carbon.Preloader.dll"
        PARSED="LD_PRELOAD=$(pwd)/libdoorstop.so ${PARSED}"
        echo "Carbon framework setup complete"
    else
        echo "WARNING: Failed to download Carbon framework, continuing without it"
    fi
elif [[ "${OXIDE:-}" == "1" ]] || [[ "${FRAMEWORK:-}" == "oxide" ]]; then
    printf "\033[1m\033[33mcontainer@phoenix~ \033[0mSetting up uMod framework...\n"
    if curl -sSL "https://github.com/OxideMod/Oxide.Rust/releases/latest/download/Oxide.Rust-linux.zip" -o umod.zip; then
        unzip -o -q umod.zip && rm umod.zip
        echo "uMod framework setup complete"
    else
        echo "WARNING: Failed to download uMod framework, continuing without it"
    fi
fi

# Fix for Rust not starting - set up library path
export LD_LIBRARY_PATH="$(pwd)/RustDedicated_Data/Plugins/x86_64:$(pwd):${LD_LIBRARY_PATH:-}"

# Display the command we're running
printf "\033[1m\033[33mcontainer@phoenix~ \033[0m%s\n" "$PARSED"

# Execute the server with wrapper
if [[ -f "/wrapper.js" ]]; then
    node /wrapper.js "$PARSED" &
else
    eval "$PARSED" &
fi

child=$!
wait "$child"
