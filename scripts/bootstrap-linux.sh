#!/usr/bin/env bash
# ==============================================================================
# Script: bootstrap-linux.sh
# Purpose: Base OS bootstrapping and software installation for Linux VMs (Ubuntu/Debian/RHEL)
# Executed via Azure Custom Script Extension (Stage 7 & 9)
# ==============================================================================
set -euo pipefail

LOG_FILE="/var/log/azure-bootstrap.log"
exec > >(tee -a "${LOG_FILE}") 2>&1

echo "[$(date -u +"%Y-%m-%dT%H:%M:%SZ")] Starting Linux VM bootstrap sequence..."

# Identify OS distribution
if [ -f /etc/os-release ]; then
    . /etc/os-release
    OS_ID=$ID
else
    echo "Cannot determine OS distribution. Exiting."
    exit 1
fi

echo "Detected OS: ${OS_ID}"

case "${OS_ID}" in
    ubuntu|debian)
        export DEBIAN_FRONTEND=noninteractive
        echo "Updating APT package lists..."
        apt-get update -y
        
        echo "Installing core dependencies and utilities..."
        apt-get install -y --no-install-recommends \
            ca-certificates \
            curl \
            gnupg \
            lsb-release \
            apt-transport-https \
            unzip \
            jq \
            git \
            htop \
            net-tools \
            chrony

        # Install Azure CLI
        if ! command -v az &>/dev/null; then
            echo "Installing Azure CLI..."
            curl -sL https://aka.ms/InstallAzureCLIDeb | bash
        fi
        ;;

    rhel|centos|rocky|almalinux)
        echo "Updating DNF/YUM repositories..."
        yum update -y
        
        echo "Installing core utilities..."
        yum install -y \
            ca-certificates \
            curl \
            unzip \
            jq \
            git \
            htop \
            net-tools \
            chrony

        # Install Azure CLI
        if ! command -v az &>/dev/null; then
            echo "Installing Azure CLI..."
            rpm --import https://packages.microsoft.com/keys/microsoft.asc
            dnf install -y https://packages.microsoft.com/config/rhel/8/packages-microsoft-prod.rpm || true
            dnf install -y azure-cli || yum install -y azure-cli
        fi
        ;;

    *)
        echo "Unsupported distribution: ${OS_ID}"
        exit 1
        ;;
esac

# Configure NTP / Chrony with Azure Host time sync
echo "Configuring chrony for Azure NTP (169.254.169.123)..."
cat << 'EOF' > /etc/chrony/chrony.conf.azure
refclock PHC /dev/ptp0 poll 3 dpoll -2 offset 0
server 169.254.169.123 prefer iburst
EOF

if [ -d /etc/chrony ]; then
    systemctl restart chrony || true
fi

# Write completion marker
cat << EOF > /var/log/bootstrap-complete.json
{
  "status": "Completed",
  "timestamp": "$(date -u +"%Y-%m-%dT%H:%M:%SZ")",
  "os": "${OS_ID}",
  "hostname": "$(hostname)"
}
EOF

echo "[$(date -u +"%Y-%m-%dT%H:%M:%SZ")] Linux VM bootstrap completed successfully."
exit 0
