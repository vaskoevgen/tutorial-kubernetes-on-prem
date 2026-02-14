FROM debian:bookworm-slim

# Avoid prompts from apt
ENV DEBIAN_FRONTEND=noninteractive

# Install systemd and dependencies for systemd
# We need to ensure systemd is the entrypoint
RUN apt-get update && apt-get install -y \
    systemd \
    systemd-sysv \
    curl \
    gnupg2 \
    software-properties-common \
    ca-certificates \
    sudo \
    kmod \
    iproute2 \
    net-tools \
    iptables \
    ebtables \
    ethtool \
    socat \
    conntrack \
    procps \
    && apt-get clean && rm -rf /var/lib/apt/lists/*

# Fix potential issues with systemd in docker
# Mask services that are not needed or might conflict
RUN find /etc/systemd/system \
    /lib/systemd/system \
    -path '*.wants/*' \
    -not -name '*journald*' \
    -not -name '*systemd-tmpfiles*' \
    -not -name '*systemd-user-sessions*' \
    -exec rm \{} \;

RUN systemctl set-default multi-user.target

# Create scripts directory
WORKDIR /usr/local/bin
RUN mkdir -p /scripts

# Copy installation script and config
COPY scripts/install_k8s.sh /scripts/install_k8s.sh
COPY scripts/kubeadm-config.yaml /scripts/kubeadm-config.yaml
RUN chmod +x /scripts/install_k8s.sh

STOPSIGNAL SIGRTMIN+3

# Start systemd
CMD ["/lib/systemd/systemd"]
