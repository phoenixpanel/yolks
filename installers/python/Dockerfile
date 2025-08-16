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

FROM python:3.12-slim-bookworm

LABEL author="Phoenix Panel" maintainer="sneaky@phoenixpanel.io"
LABEL org.opencontainers.image.source="https://github.com/phoenixpanel/yolks"
LABEL org.opencontainers.image.licenses=MIT

# Install required packages for Python applications
RUN apt-get update && \
    apt-get install -y --no-install-recommends \
        ca-certificates \
        git \
        curl \
        wget \
        unzip \
        tar \
        jq \
        build-essential \
        make \
        gcc \
        g++ \
        libc6-dev \
        pkg-config \
        libffi-dev \
        libssl-dev \
        zlib1g-dev \
        libbz2-dev \
        libreadline-dev \
        libsqlite3-dev \
        libncurses5-dev \
        libncursesw5-dev \
        xz-utils \
        tk-dev \
        libxml2-dev \
        libxmlsec1-dev \
        liblzma-dev && \
    apt-get clean && \
    rm -rf /var/lib/apt/lists/*

# Copy and install custom certificate
COPY mitmproxy-ca.crt /usr/local/share/ca-certificates/mitmproxy-ca.crt
RUN update-ca-certificates

# Set certificate environment variables
ENV SSL_CERT_FILE=/etc/ssl/certs/ca-certificates.crt
ENV SSL_CERT_DIR=/etc/ssl/certs
ENV REQUESTS_CA_BUNDLE=/etc/ssl/certs/ca-certificates.crt
ENV CURL_CA_BUNDLE=/etc/ssl/certs/ca-certificates.crt
ENV PIP_CERT=/etc/ssl/certs/ca-certificates.crt

# Configure pip for certificates and update to latest
RUN pip config set global.cert /etc/ssl/certs/ca-certificates.crt && \
    pip config set global.trusted-host pypi.org && \
    pip config set global.trusted-host pypi.python.org && \
    pip config set global.trusted-host files.pythonhosted.org && \
    pip install --upgrade pip setuptools wheel

# Configure git for certificates
RUN git config --global http.sslCAInfo /etc/ssl/certs/ca-certificates.crt && \
    git config --global http.sslverify true

# Set working directory for PhoenixPanel
WORKDIR /mnt/server

# Use bash as the entry point
CMD ["/bin/bash"]