FROM debian:13-slim

ENV DEBIAN_FRONTEND=noninteractive
ENV JAVA_HOME=/usr/lib/jvm/temurin-25-jdk
ENV PATH="$JAVA_HOME/bin:$PATH"

# Required packages for Pterodactyl
RUN apt-get update && apt-get install -y \
    ca-certificates \
    curl \
    gnupg \
    lsb-release \
    tzdata \
    bash \
    openssl \
    unzip \
    && rm -rf /var/lib/apt/lists/*

# Add Adoptium (Eclipse Temurin) repository
RUN mkdir -p /etc/apt/keyrings && \
    curl -fsSL https://packages.adoptium.net/artifactory/api/gpg/key/public \
        | gpg --dearmor -o /etc/apt/keyrings/adoptium.gpg && \
    echo "deb [signed-by=/etc/apt/keyrings/adoptium.gpg] \
        https://packages.adoptium.net/artifactory/deb \
        $(lsb_release -cs) main" \
        > /etc/apt/sources.list.d/adoptium.list

# Install Temurin OpenJDK 25
RUN apt-get update && \
    apt-get install -y temurin-25-jdk && \
    rm -rf /var/lib/apt/lists/*



# Pterodactyl expects this directory
RUN mkdir -p /home/container
WORKDIR /home/container

ENV NODE_VERSION=20.19.5
RUN apt install -y curl
RUN curl -o- https://raw.githubusercontent.com/nvm-sh/nvm/v0.39.0/install.sh | bash
ENV NVM_DIR=/root/.nvm
RUN . "$NVM_DIR/nvm.sh" && nvm install ${NODE_VERSION}
RUN . "$NVM_DIR/nvm.sh" && nvm use v${NODE_VERSION}
RUN . "$NVM_DIR/nvm.sh" && nvm alias default v${NODE_VERSION}
ENV PATH="/node/bin/:${PATH}"
RUN mv /root/.nvm/versions/node/v$NODE_VERSION /node
RUN chmod 755 -R /node
RUN node --version
RUN npm --version

# Copy entrypoint
COPY main.js /main.js
RUN chmod 755 /main.js
COPY entrypoint.sh /entrypoint.sh
RUN chmod +x /entrypoint.sh
COPY start.sh /start.sh
RUN chmod +x /start.sh

CMD ["/entrypoint.sh"]
