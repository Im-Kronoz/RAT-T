#!/bin/bash

# ───────────────────────────────
# 🧩 Installer for RAT-T (by Im-Kronoz)
# Installs required dependencies and sets execution permissions
# ───────────────────────────────

# Colors
red="\033[31m"
green="\033[32m"
none="\033[0m"

# verify if the script is run as root
if [ "$EUID" -ne 0 ]; then
    echo -e "${red}[!] Please run this installer as root or with sudo.${none}"
    exit 1
fi

# show message
echo -e "${green}[+] Installing dependencies for RAT-T🐀...${none}"
sleep 1

# list of required packages
packages=(
  ethtool
  pciutils
  iproute2
  wireless-tools
  iw
  nmap
  net-tools
  grep
  gawk
  sed
  coreutils
)

# Packages installation loop
for pkg in "${packages[@]}"; do
    if ! dpkg -s "$pkg" &>/dev/null; then
        echo -e "${green}[*] Installing $pkg...${none}"
        apt-get install -y "$pkg"
    else
        echo -e "${green}[*] $pkg is already installed.${none}"
    fi
done

# Give permissions to RAT-T.sh
if [ -f "RAT-T.sh" ]; then
    chmod +777 RAT-T.sh
    echo -e "${green}[+] RAT-T.sh is now executable (chmod +777).${none}"
else
    echo -e "${red}[!] RAT-T.sh not found in current directory.${none}"
fi

echo -e "${green}[✓] Installation complete. You can now run ./RAT-T.sh${none}"
