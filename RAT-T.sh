#!/bin/bash

#running as root?

if [ "$EUID" -ne 0 ]; then
  echo "This script must be excecuted with root privileges. try running this script with 'sudo'."
  exit 1
fi
clear
# ──────────────────── Terminal Colors ──────────────────────

none="\033[0m"
red="\033[31m"
green="\033[32m"
blue="\033[34m"
purple="\033[35m"
cyan="\033[36m"
yellow="\033[33m"

# ────────────────────────────────────────────────
# 🐀 RAT-T (Recon And Targeting - Toolkit)
# Autor: Im-Kronoz
# Description: Network scanning, ports and services
# ────────────────────────────────────────────────

function logo() {
  echo " "
  echo " "
  echo " "
  echo -e "${red} "
  echo -e "║██████████       ║██       ║████        █████       ║████        █████  "
  echo -e "╚╗██══════╗██     ╚╗███     ║██═╗█████████           ║██═╗█████████      "
  echo -e " ╚╗██     ╚╗██     ╚╗███    ╚╗█ ╚═════╗██            ╚╗█ ╚═════╗██       "
  echo -e "  ╚╗██     ╚╗█      ╚╗████   ╚╗█      ╚╗█             ╚╗█      ╚╗█       "
  echo -e "   ╚╗█      ║█       ╚╗█╗██   ╚╗       ║██             ╚╗       ║██      "
  echo -e "    ║█      ██        ║█╚╗██           ╚╗█                      ╚╗█      "
  echo -e "    ║██   ███         ║█ ╚╗███          ║██                      ║██     "
  echo -e "    ╚╗███████         ║██ ╚═╗██         ╚╗█          █████       ╚╗█     "
  echo -e "     ║█════╗███       ╚╗█   ╚╗██         ║█     █████             ║█     "
  echo -e "     ║█    ╚═╗██       ║█   ████         ║█                       ║█     "
  echo -e "     ║█      ╚╗█       ║████══╗██        ╚╗█                      ╚╗█    "
  echo -e "     ██       ║█       ██     ╚╗█         ║█                       ║█    "
  echo -e "    ██        ║█      ██       ║██        ║█                       ║█    "
  echo -e "  ███         ║██   ███        ╚╗██       ╚╗█                      ╚╗█   "
  echo -e " ██           ╚╗█   █           ╚╗█        ╚╗██                     ╚╗██ ${purple}"
  echo -e "                                 ╥        ╥          ╖  ╓                "
  echo -e "                                 ╠═╗╓ ╖ ■ ║╠═╦═╗     ║ ╔╝╖╓╔═╗╓─╖╔═╗╒══╕ "
  echo -e "                                 ║ ║║ ║ ■ ║║ ║ ║ ═══ ╠═╩╗╠╝║ ║║ ║║ ║┌──┘ "
  echo -e "                                 ╚═╝╚╦╝   ╨╨ ╨ ╨     ╜  ╨╨ ╚═╝╨ ╨╚═╝╘══╛ "
  echo -e "                                  ╘══╝                                   ${none}"
  echo " "
  echo " "
  echo -e "${cyan} "
  echo -e "🐀 RAT-T (Recon And Targeting - Toolkit)${none}"
}

logo
sleep 4.5
clear

#colores 

red="\033[31m"
none="\033[0m"

#---

get_chipset() {
    local iface=$1
    driver=$(ethtool -i "$iface" 2>/dev/null | grep driver | awk '{print $2}')
    if [ -n "$driver" ]; then
        vendor=$(cat /sys/class/net/"$iface"/device/vendor 2>/dev/null)
        device=$(cat /sys/class/net/"$iface"/device/device 2>/dev/null)
        if [ -n "$vendor" ] && [ -n "$device" ]; then
            desc=$(lspci -nn | grep -i "${vendor:2:4}:${device:2:4}" | head -n1 | cut -d':' -f3-)
            if [ -n "$desc" ]; then
                desc_clean=$(echo "$desc" | \
                    sed 's/Gigabit.*//I' | \
                    sed 's/Wireless.*//I')
                echo "$desc_clean"
                return
            fi
        fi
        echo "$driver"
        return
    fi
    echo "Unknown"
}

# Función para detectar bandas WiFi soportadas

get_bands() {
    local iface=$1
    local phy=""
    local found=false

    while read -r line; do
        if [[ "$line" =~ ^phy#([0-9]+) ]]; then
            phy="phy${BASH_REMATCH[1]}"
        elif [[ "$line" =~ Interface[[:space:]]+$iface ]]; then
            found=true
            break
        fi
    done < <(iw dev)

    if ! $found || [ -z "$phy" ]; then
        echo ""
        return
    fi

    local supports_24ghz=false
    local supports_5ghz=false

    freqs=$(iw phy "$phy" info | awk '/\* [0-9]+(\.[0-9]+)? MHz/ {print $2}')


    for freq in $freqs; do
        freq_int=$(printf "%.0f" "$freq")  # Redondear y quitar decimales

        if [[ "$freq_int" -ge 2400 && "$freq_int" -le 2500 ]]; then
            supports_24ghz=true
        elif [[ "$freq_int" -ge 5000 && "$freq_int" -le 5900 ]]; then
            supports_5ghz=true
        fi
    done


    local bands=""
    if $supports_24ghz; then
        bands="2.4Ghz"
    fi
    if $supports_5ghz; then
        if [ -n "$bands" ]; then
            bands="$bands, 5Ghz"
        else
            bands="5Ghz"
        fi
    fi

    echo "$bands"
}

# Obtenemos interfaces UP excepto loopback

interfaces=()
while read -r line; do
    iface=$(echo "$line" | awk '{print $2}' | sed 's/://') # quitamos ':'
    if [ "$iface" != "lo" ]; then
        interfaces+=("$iface")
    fi
done < <(ip -o link show up)

echo "------------------------------ Interface selection ------------------------------"
echo "Select an interface to work with:"
echo "---------"

index=1
declare -A iface_map

for iface in "${interfaces[@]}"; do
    chipset=$(get_chipset "$iface")
    bands=$(get_bands "$iface")

    if [ -z "$bands" ]; then
        echo -e "$index.  $iface // ${red}Chipset:${none}$chipset"
    else
        echo -e "$index.  $iface // $bands // ${red}Chipset:${none}$chipset"
    fi
    iface_map[$index]="$iface"
    ((index++))
done

echo "---------"
read -p "> " selection

selected_iface=${iface_map[$selection]}
if [ -z "$selected_iface" ]; then
    echo "Invalid selection."
    exit 1
fi

echo "You selected interface: $selected_iface"




function client_scan() {
    echo "[*] Scanning Network Clients $selected_iface..."
    MIRED=$(ip addr show "$selected_iface" | grep "inet " | awk '{print $2}' | cut -d/ -f1 | sed 's/\.[0-9]*$/.0/')

    nmap -sn "$MIRED/24" -oG /tmp/scan.txt > /dev/null
    grep "Up" /tmp/scan.txt | awk '{print $2}' > /tmp/clients.txt

    echo
    echo "[*] Detected Clients:"
    count=1
    while read -r ip; do
        echo "$count) $ip"
        clients["$count"]=$ip
        ((count++))
    done < /tmp/clients.txt
    
    echo
    read -p "[?] Select client to scan: " option
    OBJETIVE=${clients[$option]}

    if [[ -z "$OBJETIVE" ]]; then
        echo "[!] Invalid Objetive. Exiting..."
        exit 1
    fi

    echo "[+] Selected Objetive: $OBJETIVE"
    sleep 1
}

function select_scan_type() {
    echo
    echo "[*] What kind of ports do you want to scan?"
    echo "1) TCP"
    echo "2) UDP"
    echo "3) Both"
    read -p "[?] choose an option: " tipe

    case $tipe in
        1) TIPE="-sS";;
        2) TIPE="-sU";;
        3) tipe="-sS -sU";;
        *) echo "[!] Invalid option."; exit 1;;
    esac
}

function select_state() {
    echo
    echo "[*] What kind of results do you want to keep?"
    echo "1) Only open"
    echo "2) Open and filtered"
    read -p "[?] choose an option: " estate

    case $estate in
        1) ESTATE="open";;
        2) ESTATE="open|filtered";;
        *) echo "[!] Invalid option."; exit 1;;
    esac
}

function portscan_and_services() {
    echo "[*] Starting port and services scanning $OBJETIVE..."
    echo
    nmap $TIPE -sCV --open $OBJETIVE -Pn -oG - --min-rate 1500  -vvv | grep -E "$ESTATE" | tee results.txt
    echo
    echo "[+] The scan is complete. Results saved in results.txt"
}

client_scan
select_scan_type
select_state
portscan_and_services
