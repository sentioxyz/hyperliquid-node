FROM ubuntu:24.04

ARG USERNAME=hluser
ARG USER_UID=10000
ARG USER_GID=$USER_UID

# Define URLs as environment variables
ARG PUB_KEY_URL=https://raw.githubusercontent.com/hyperliquid-dex/node/refs/heads/main/pub_key.asc
ARG HL_VISOR_URL=https://binaries.hyperliquid-testnet.xyz/Testnet/hl-visor
ARG HL_VISOR_ASC_URL=https://binaries.hyperliquid-testnet.xyz/Testnet/hl-visor.asc

# Create user and install dependencies
RUN groupadd --gid $USER_GID $USERNAME \
    && useradd --uid $USER_UID --gid $USER_GID -m $USERNAME \
    && apt-get update -y && apt-get install -y curl gnupg \
    && apt-get clean && rm -rf /var/lib/apt/lists/* \
    && mkdir -p /home/$USERNAME/hl/data && chown -R $USERNAME:$USERNAME /home/$USERNAME/hl

USER $USERNAME
WORKDIR /home/$USERNAME

# Configure chain to testnet
RUN echo '{"chain": "Mainnet"}' > /home/$USERNAME/visor.json


RUN mkdir -p /home/$USERNAME && \
  cat <<EOF > /home/$USERNAME/override_gossip_config.json
{
  "root_node_ips": [
    {"Ip": "64.31.48.111"},
    {"Ip": "64.31.51.137"},
    {"Ip": "180.189.55.18"},
    {"Ip": "180.189.55.19"},
    {"Ip": "46.105.222.166"},
    {"Ip": "91.134.41.52"},
    {"Ip": "13.230.78.76"},
    {"Ip": "54.248.41.39"},
    {"Ip": "52.68.71.160"},
    {"Ip": "13.114.116.44"},
    {"Ip": "199.254.199.190"},
    {"Ip": "199.254.199.247"},
    {"Ip": "45.32.32.21"},
    {"Ip": "157.90.207.92"},
    {"Ip": "148.251.76.7"},
    {"Ip": "109.123.230.189"},
    {"Ip": "31.223.196.172"},
    {"Ip": "31.223.196.238"},
    {"Ip": "91.134.71.237"},
    {"Ip": "57.129.140.247"},
    {"Ip": "160.202.131.51"},
    {"Ip": "72.46.87.141"},
    {"Ip": "199.254.199.12"},
    {"Ip": "199.254.199.54"},
    {"Ip": "45.250.255.111"},
    {"Ip": "109.94.99.131"},
    {"Ip": "8.220.222.129"},
    {"Ip": "8.220.213.65"},
    {"Ip": "144.168.36.162"},
    {"Ip": "181.41.140.106"}
    ],
  "try_new_peers": false,
  "chain": "Mainnet"
}
EOF


# Import GPG public key
RUN curl -o /home/$USERNAME/pub_key.asc $PUB_KEY_URL \
    && gpg --import /home/$USERNAME/pub_key.asc

# Download and verify hl-visor binary
RUN curl -o /home/$USERNAME/hl-visor $HL_VISOR_URL \
    && curl -o /home/$USERNAME/hl-visor.asc $HL_VISOR_ASC_URL \
    && gpg --verify /home/$USERNAME/hl-visor.asc /home/$USERNAME/hl-visor \
    && chmod +x /home/$USERNAME/hl-visor

# Expose gossip ports
EXPOSE 4000-4010

# Run a non-validating node
ENTRYPOINT ["/home/hluser/hl-visor", "run-non-validator", "--replica-cmds-style", "recent-actions"]
