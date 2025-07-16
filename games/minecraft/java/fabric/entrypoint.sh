#!/bin/bash

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

# Default the TZ environment variable to UTC.
TZ=${TZ:-UTC}
export TZ

# Set environment variable that holds the Internal Docker IP
INTERNAL_IP=$(ip route get 1 | awk '{print $(NF-2);exit}')
export INTERNAL_IP

# Switch to the container's working directory
cd /home/container || exit 1

# Print Java information
printf "\033[1m\033[33mcontainer@phoenix~ \033[0m"
java --version | head -n 1

# Auto-update Fabric if enabled
if [[ "${AUTO_UPDATE}" == "1" ]]; then
    printf "\033[1m\033[33mcontainer@phoenix~ \033[0mChecking for Fabric updates...\n"
    
    MC_VERSION=${MC_VERSION:-"1.20.4"}
    LOADER_VERSION=$(curl -s "https://meta.fabricmc.net/v2/versions/loader" | jq -r '.[0].version')
    INSTALLER_VERSION=$(curl -s "https://meta.fabricmc.net/v2/versions/installer" | jq -r '.[0].version')
    
    SERVER_JAR="fabric-server-mc.${MC_VERSION}-loader.${LOADER_VERSION}-launcher.${INSTALLER_VERSION}.jar"
    
    if [[ ! -f "${SERVER_JAR}" ]]; then
        printf "\033[1m\033[33mcontainer@phoenix~ \033[0mDownloading Fabric server ${MC_VERSION}...\n"
        curl -o "${SERVER_JAR}" "https://meta.fabricmc.net/v2/versions/loader/${MC_VERSION}/${LOADER_VERSION}/${INSTALLER_VERSION}/server/jar"
        
        # Remove old versions
        find . -name "fabric-server-*.jar" ! -name "${SERVER_JAR}" -delete
    fi
fi

# Accept EULA if specified
if [[ "${ACCEPT_EULA}" == "true" ]]; then
    echo "eula=true" > eula.txt
fi

# Convert all of the "{{VARIABLE}}" parts of the command into the expected shell
# variable format of "${VARIABLE}" before evaluating the string and automatically
# replacing the values.
PARSED=$(echo "${STARTUP}" | sed -e 's/{{/${/g' -e 's/}}/}/g' | eval echo "$(cat -)")

# Display the command we're running in the output, and then execute it with the env
# from the container itself.
printf "\033[1m\033[33mcontainer@phoenix~ \033[0m%s\n" "$PARSED"

# shellcheck disable=SC2086
exec env ${PARSED}