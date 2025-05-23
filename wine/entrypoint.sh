#!/bin/bash
#
# Docker entrypoint script for Wine container
# This script handles initialization, updates, and launching of Windows applications through Wine

#------------------------------------------------------------------------------
# INITIALIZATION
#------------------------------------------------------------------------------

clear

# Define color codes for output
RED='\033[0;31m'
GREEN='\033[0;32m'
YELLOW='\033[1;33m'
BLUE='\033[0;34m'
NC='\033[0m'  # No Color

# Get Linux distribution information
LINUX=$(. /etc/os-release; echo ${PRETTY_NAME})

# Wait for the container to fully initialize
sleep 1

# Default the TZ environment variable to UTC
TZ=${TZ:-UTC}
export TZ

#------------------------------------------------------------------------------
# INFORMATION OUTPUT
#------------------------------------------------------------------------------

echo -e "${BLUE}---------------------------------------------------------------------${NC}"
echo -e "${YELLOW}Docker Linux Distribution: ${RED}${LINUX}${NC}"
echo -e "${YELLOW}Current timezone: $(cat /etc/timezone)${NC}"
echo -e "${YELLOW}Wine Version: ${RED}$(wine --version)${NC}"
echo -e "${BLUE}---------------------------------------------------------------------${NC}"

#------------------------------------------------------------------------------
# ENVIRONMENT SETUP
#------------------------------------------------------------------------------

# Set environment variable that holds the Internal Docker IP
INTERNAL_IP=$(ip route get 1 | awk '{print $(NF-2);exit}')
export INTERNAL_IP

# Switch to the container's working directory
cd /home/container || exit 1

#------------------------------------------------------------------------------
# STEAM USER CONFIGURATION
#------------------------------------------------------------------------------

# Set up Steam user credentials
if [ "${STEAM_USER}" == "" ]; then
    echo -e "${BLUE}---------------------------------------------------------------------${NC}"
    echo -e "${YELLOW}Steam user is not set.${NC}"
    echo -e "${YELLOW}Using anonymous user.${NC}"
    echo -e "${BLUE}---------------------------------------------------------------------${NC}"
    STEAM_USER="anonymous"
    STEAM_PASS=""
    STEAM_AUTH=""
else
    echo -e "${BLUE}---------------------------------------------------------------------${NC}"
    echo -e "${YELLOW}User set to ${STEAM_USER}${NC}"
    echo -e "${BLUE}---------------------------------------------------------------------${NC}"
fi

#------------------------------------------------------------------------------
# GAME SERVER UPDATE
#------------------------------------------------------------------------------

# Update game server if auto_update is enabled or not set
if [ -z ${AUTO_UPDATE} ] || [ "${AUTO_UPDATE}" == "1" ]; then
    if [ -f /home/container/DepotDownloader ]; then
        ./DepotDownloader -dir /home/container \
                         -username ${STEAM_USER} \
                         -password ${STEAM_PASS} \
                         -remember-password $( [[ "${WINDOWS_INSTALL}" == "1" ]] && printf %s '-os windows' ) \
                         -app ${STEAM_APPID} \
                         $( [[ -z ${STEAM_BETAID} ]] || printf %s "-branch ${STEAM_BETAID}" ) \
                         $( [[ -z ${STEAM_BETAPASS} ]] || printf %s "-branchpassword ${STEAM_BETAPASS}" )
        
        # Setup Steam SDK
        mkdir -p /home/container/.steam/sdk64
        ./DepotDownloader -dir /home/container/.steam/sdk64 \
                         $( [[ "${WINDOWS_INSTALL}" == "1" ]] && printf %s '-os windows' ) \
                         -app 1007
        chmod +x ${HOME}/*
    else
        ./steamcmd/steamcmd.sh +force_install_dir /home/container \
                              +login ${STEAM_USER} ${STEAM_PASS} ${STEAM_AUTH} \
                              $( [[ "${WINDOWS_INSTALL}" == "1" ]] && printf %s '+@sSteamCmdForcePlatformType windows' ) \
                              $( [[ "${STEAM_SDK}" == "1" ]] && printf %s '+app_update 1007' ) \
                              +app_update ${STEAM_APPID} \
                              $( [[ -z ${STEAM_BETAID} ]] || printf %s "-beta ${STEAM_BETAID}" ) \
                              $( [[ -z ${STEAM_BETAPASS} ]] || printf %s "-betapassword ${STEAM_BETAPASS}" ) \
                              ${INSTALL_FLAGS} \
                              $( [[ "${VALIDATE}" == "1" ]] && printf %s 'validate' ) \
                              +quit
    fi
else
    echo -e "${BLUE}---------------------------------------------------------------------${NC}"
    echo -e "${YELLOW}Not updating game server as auto update was set to 0. Starting Server${NC}"
    echo -e "${BLUE}---------------------------------------------------------------------${NC}"
fi

#------------------------------------------------------------------------------
# DISPLAY SETUP
#------------------------------------------------------------------------------

# Set up X virtual framebuffer if enabled
if [[ ${XVFB} == 1 ]]; then
    Xvfb :0 -screen 0 ${DISPLAY_WIDTH}x${DISPLAY_HEIGHT}x${DISPLAY_DEPTH} &
fi

#------------------------------------------------------------------------------
# WINE CONFIGURATION
#------------------------------------------------------------------------------

# Create Wine prefix directory
echo -e "${BLUE}---------------------------------------------------------------------${NC}"
echo -e "${RED}First launch will throw some errors. Ignore them${NC}"
echo -e "${BLUE}---------------------------------------------------------------------${NC}"
mkdir -p ${WINEPREFIX}

#------------------------------------------------------------------------------
# WINE GECKO INSTALLATION
#------------------------------------------------------------------------------

# Install Wine Gecko if required
if [[ ${WINETRICKS_RUN} =~ gecko ]]; then
    echo -e "${BLUE}---------------------------------------------------------------------${NC}"
    echo -e "${YELLOW}Installing Wine Gecko${NC}"
    echo -e "${BLUE}---------------------------------------------------------------------${NC}"
    WINETRICKS_RUN=${WINETRICKS_RUN/gecko/}

    # Download and install 32-bit Gecko
    if [ ! -f "${WINEPREFIX}/gecko_x86.msi" ]; then
        wget -q -O ${WINEPREFIX}/gecko_x86.msi http://dl.winehq.org/wine/wine-gecko/2.47.4/wine_gecko-2.47.4-x86.msi
    fi

    # Download and install 64-bit Gecko
    if [ ! -f "${WINEPREFIX}/gecko_x86_64.msi" ]; then
        wget -q -O ${WINEPREFIX}/gecko_x86_64.msi http://dl.winehq.org/wine/wine-gecko/2.47.4/wine_gecko-2.47.4-x86_64.msi
    fi

    # Install Gecko packages
    wine msiexec /i ${WINEPREFIX}/gecko_x86.msi /qn /quiet /norestart /log ${WINEPREFIX}/gecko_x86_install.log
    wine msiexec /i ${WINEPREFIX}/gecko_x86_64.msi /qn /quiet /norestart /log ${WINEPREFIX}/gecko_x86_64_install.log
fi

#------------------------------------------------------------------------------
# WINE MONO INSTALLATION
#------------------------------------------------------------------------------

# Install Wine Mono if required
if [[ ${WINETRICKS_RUN} =~ mono ]]; then
    echo -e "${BLUE}---------------------------------------------------------------------${NC}"
    echo -e "${YELLOW}Installing Wine Mono${NC}"
    echo -e "${BLUE}---------------------------------------------------------------------${NC}"
    WINETRICKS_RUN=${WINETRICKS_RUN/mono/}

    # Download Mono
    if [ ! -f "${WINEPREFIX}/mono.msi" ]; then
        wget -q -O ${WINEPREFIX}/mono.msi https://dl.winehq.org/wine/wine-mono/10.0.0/wine-mono-10.0.0-x86.msi
    fi

    # Install Mono
    wine msiexec /i ${WINEPREFIX}/mono.msi /qn /quiet /norestart /log ${WINEPREFIX}/mono_install.log
fi

#------------------------------------------------------------------------------
# WINETRICKS INSTALLATION
#------------------------------------------------------------------------------

# Install additional packages using winetricks
for trick in ${WINETRICKS_RUN}; do
    echo -e "${BLUE}---------------------------------------------------------------------${NC}"
    echo -e "${YELLOW}Installing: ${NC} ${GREEN}${trick}${NC}"
    echo -e "${BLUE}---------------------------------------------------------------------${NC}"
    winetricks -q ${trick}
done

#------------------------------------------------------------------------------
# SERVER STARTUP
#------------------------------------------------------------------------------

# Replace Startup Variables
MODIFIED_STARTUP=$(echo ${STARTUP} | sed -e 's/{{/${/g' -e 's/}}/}/g')
echo ":/home/container$ ${MODIFIED_STARTUP}"

# Run the Server
eval ${MODIFIED_STARTUP}
