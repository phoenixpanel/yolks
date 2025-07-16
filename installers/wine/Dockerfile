FROM        --platform=$TARGETOS/$TARGETARCH debian:bookworm-slim

LABEL       author="Phoenix Panel" maintainer="sneaky@phoenixpanel.io"

LABEL       org.opencontainers.image.source="https://github.com/phoenixpanel/yolks"
LABEL       org.opencontainers.image.licenses=MIT

## update base packages
ARG         DEBIAN_FRONTEND noninteractive
RUN        	dpkg --add-architecture i386
RUN         apt update \
            && apt -y upgrade

RUN		 	apt install -y --no-install-recommends \
				build-essential \
				ca-certificates \
				curl \
				file \
				git \
				git-lfs \
				jq \
				locales \
				python3 \
               	python3-dev \
               	python3-pip \
				tar \
				unzip \
				wget \
				zstd \
				lib32gcc-s1 \
				libcurl4 \
				libcurl4-gnutls-dev \
				libsdl2-2.0-0

## download lastest 7zip for archives
RUN 	wget https://www.7-zip.org/a/7z2409-linux-x64.tar.xz \
			&& tar xf 7z2409-linux-x64.tar.xz \
			&& mv 7zz /usr/local/bin \
			&& rm -f 7z2409-linux-x64.tar.xz

# Install wine and with recommends
RUN             mkdir -pm755 /etc/apt/keyrings
RUN             wget -O /etc/apt/keyrings/winehq-archive.key https://dl.winehq.org/wine-builds/winehq.key
RUN             wget -NP /etc/apt/sources.list.d/ https://dl.winehq.org/wine-builds/debian/dists/bookworm/winehq-bookworm.sources
RUN             apt update
RUN             apt install -y --install-recommends \
					winehq-staging \
					winbind \
					cabextract
RUN             rm -rf /var/lib/apt/lists/*
