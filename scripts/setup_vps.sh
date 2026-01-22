#!/bin/bash

# ==========================================
# StructIO VPS Provisioning Script
# Runs on: Ubuntu 24.04 (Hetzner x86)
# ==========================================

# Stop script on first error
set -e

# Configuration
FRP_VERSION="0.61.0"
APP_DIR="/var/www/structio"

GREEN='\033[0;32m'
YELLOW='\033[1;33m'
NC='\033[0m'

echo -e "${GREEN} Starting StructIO VPS Setup...${NC}"

# ------------------------------------------
# System Updates & Basic Tools
# ------------------------------------------
echo -e "${YELLOW}[1/6] Updating System & Installing Base Tools...${NC}"
apt update && apt upgrade -y
apt install -y curl wget git unzip tar ufw fail2ban nano

# ------------------------------------------
# Firewall Security
# ------------------------------------------
echo -e "${YELLOW}[2/6] Configuring Firewall...${NC}"
# Reset to default
ufw --force reset
ufw default deny incoming
ufw default allow outgoing

# Allow Services
ufw allow 22/tcp        # SSH
ufw allow 80/tcp        # HTTP (Caddy)
ufw allow 443/tcp       # HTTPS (Caddy)
ufw allow 7000/tcp      # FRP Tunnel Port

# Enable Firewall 
echo "y" | ufw enable
echo -e "${GREEN}✔ Firewall is active.${NC}"

# ------------------------------------------
# Install Caddy
# ------------------------------------------
echo -e "${YELLOW}[3/6] Installing Caddy...${NC}"
if ! command -v caddy &> /dev/null; then
    apt install -y debian-keyring debian-archive-keyring apt-transport-https
    curl -1sLf 'https://dl.cloudsmith.io/public/caddy/stable/gpg.key' | gpg --dearmor -o /usr/share/keyrings/caddy-stable-archive-keyring.gpg
    curl -1sLf 'https://dl.cloudsmith.io/public/caddy/stable/debian.deb.txt' | tee /etc/apt/sources.list.d/caddy-stable.list
    apt update
    apt install -y caddy
    echo -e "${GREEN}✔ Caddy installed.${NC}"
else
    echo -e "${GREEN}✔ Caddy already installed.${NC}"
fi

# ------------------------------------------
# Install FRP Server 
# ------------------------------------------
echo -e "${YELLOW}[4/6] Installing FRP Server v${FRP_VERSION}...${NC}"
if [ ! -f "/usr/local/bin/frps" ]; then
    cd /tmp
    wget -q "https://github.com/fatedier/frp/releases/download/v${FRP_VERSION}/frp_${FRP_VERSION}_linux_amd64.tar.gz"
    tar -xzf "frp_${FRP_VERSION}_linux_amd64.tar.gz"
    
    # Move binary
    mv "frp_${FRP_VERSION}_linux_amd64/frps" /usr/local/bin/
    chmod +x /usr/local/bin/frps
    
    # Create Config Dir
    mkdir -p /etc/frp
    
    # Cleanup
    rm -rf frp_*
    echo -e "${GREEN}✔ FRP Server installed.${NC}"
else
    echo -e "${GREEN}✔ FRP Server already installed.${NC}"
fi


echo -e "${YELLOW}[5/6] Creating Directory Structure...${NC}"

mkdir -p "$APP_DIR/dist"   
mkdir -p "$APP_DIR/data"   

# Set Permissions (Root owns it for now, can change if using a specific user)
chmod -R 755 "$APP_DIR"

echo -e "${GREEN}✔ Directories created at $APP_DIR${NC}"


echo -e "${GREEN}==============================================${NC}"
echo -e "${GREEN}SETUP COMPLETE!${NC}"
echo -e "${GREEN}==============================================${NC}"
echo -e "${YELLOW}Next Steps (Manual Config):${NC}"
echo "1. Upload your Caddyfile to: /etc/caddy/Caddyfile"
echo "2. Upload your frps.toml to: /etc/frp/frps.toml"
echo "3. Upload your Service files (.service) to: /etc/systemd/system/"
echo "4. Reload systemd: systemctl daemon-reload"
echo "5. Start services:"
echo "   - systemctl restart frps"
echo "   - systemctl restart caddy"
echo "   - systemctl restart structio-portal"
echo ""