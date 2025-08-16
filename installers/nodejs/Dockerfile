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

FROM        node:20-bookworm-slim

LABEL       author="Phoenix Panel" maintainer="sneaky@phoenixpanel.io"
LABEL       org.opencontainers.image.source="https://github.com/phoenixpanel/yolks"
LABEL       org.opencontainers.image.licenses=MIT

# Install system packages and build tools
RUN         apt-get update && apt-get install -y \
                ca-certificates \
                git \
                curl \
                jq \
                file \
                unzip \
                make \
                gcc \
                g++ \
                python3 \
                python3-dev \
                python3-pip \
                libtool \
                build-essential \
            && rm -rf /var/lib/apt/lists/*

# Copy and install custom certificate for system-wide trust
COPY        mitmproxy-ca.crt /usr/local/share/ca-certificates/mitmproxy-ca.crt
RUN         update-ca-certificates

# Configure certificate trust for all tools
ENV         NODE_EXTRA_CA_CERTS=/etc/ssl/certs/ca-certificates.crt
ENV         CURL_CA_BUNDLE=/etc/ssl/certs/ca-certificates.crt
ENV         SSL_CERT_FILE=/etc/ssl/certs/ca-certificates.crt
ENV         SSL_CERT_DIR=/etc/ssl/certs
ENV         REQUESTS_CA_BUNDLE=/etc/ssl/certs/ca-certificates.crt

# Configure npm to use the updated certificate bundle
RUN         npm config set cafile /etc/ssl/certs/ca-certificates.crt \
            && npm config set strict-ssl true \
            && npm config set registry https://registry.npmjs.org/

# Update npm to latest version
RUN         NODE_EXTRA_CA_CERTS=/etc/ssl/certs/ca-certificates.crt npm install -g npm@latest

# Configure Git to trust the certificate
RUN         git config --global http.sslCAInfo /etc/ssl/certs/ca-certificates.crt \
            && git config --global http.sslverify true

WORKDIR     /mnt/server
CMD         ["/bin/bash"]