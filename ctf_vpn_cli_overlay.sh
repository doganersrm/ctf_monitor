#!/bin/bash
# CTF VPN Monitor - CLI Interface

CONFIG_FILE="$HOME/.ctf_vpn_config.json"
SCRIPT_DIR="$(cd "$(dirname "${BASH_SOURCE[0]}")" && pwd)"
OVERLAY_SCRIPT="$SCRIPT_DIR/ctf_vpn_overlay.py"

# Renk kodları
RED='\033[0;31m'
GREEN='\033[0;32m'
YELLOW='\033[1;33m'
BLUE='\033[0;34m'
CYAN='\033[0;36m'
NC='\033[0m'

show_help() {
    echo -e "${CYAN}╔════════════════════════════════════════════════════╗${NC}"
    echo -e "${CYAN}║${NC}       ${BLUE}CTF VPN Monitor${NC} - Overlay Edition    ${CYAN}║${NC}"
    echo -e "${CYAN}╚════════════════════════════════════════════════════╝${NC}"
    echo ""
    echo -e "${YELLOW}Kullanım:${NC}"
    echo "  $0 overlay                  - Overlay'i başlat"
    echo "  $0 target -u <IP>           - Hedef IP ayarla"
    echo "  $0 target --clear           - Hedef IP'yi temizle"
    echo "  $0 status                   - Mevcut durumu göster"
    echo "  $0 stop                     - Overlay'i durdur"
    echo "  $0 restart                  - Overlay'i yeniden başlat"
    echo "  $0 install                  - Gerekli paketleri kur"
    echo ""
    echo -e "${YELLOW}Örnekler:${NC}"
    echo "  $0 overlay                   # Overlay'i başlat"
    echo "  $0 target -u 10.10.11.202   # Hedef IP ayarla"
    echo "  $0 status                    # Durum göster"
}

get_vpn_ip() {
    ip addr show tun0 2>/dev/null | grep -oP 'inet \K[\d.]+'
}

get_local_ip() {
    for iface in eth0 wlan0 ens33 enp0s3; do
        local ip=$(ip addr show $iface 2>/dev/null | grep -oP 'inet \K[\d.]+' | head -1)
        if [ -n "$ip" ]; then
            echo "$ip"
            return
        fi
    done
}

get_target_ip() {
    if [ -f "$CONFIG_FILE" ]; then
        python3 -c "import json; print(json.load(open('$CONFIG_FILE')).get('target_ip', ''))" 2>/dev/null
    fi
}

set_target_ip() {
    local ip=$1
    
    if [[ ! $ip =~ ^[0-9]{1,3}\.[0-9]{1,3}\.[0-9]{1,3}\.[0-9]{1,3}$ ]]; then
        echo -e "${RED}✗ Hata: Geçersiz IP formatı!${NC}"
        echo "Örnek: $0 target -u 10.10.11.202"
        exit 1
    fi
    
    echo "{\"target_ip\": \"$ip\"}" > "$CONFIG_FILE"
    echo -e "${GREEN}✓ Hedef IP ayarlandı: ${YELLOW}$ip${NC}"
    
    if pgrep -f "ctf_vpn_overlay.py" > /dev/null; then
        echo -e "${CYAN}ℹ Overlay çalışıyor, bilgiler otomatik güncellenecek${NC}"
    fi
}

clear_target_ip() {
    echo "{\"target_ip\": \"\"}" > "$CONFIG_FILE"
    echo -e "${GREEN}✓ Hedef IP temizlendi${NC}"
}

show_status() {
    local vpn_ip=$(get_vpn_ip)
    local local_ip=$(get_local_ip)
    local target_ip=$(get_target_ip)
    
    echo -e "${CYAN}╔════════════════════════════════════════════════════╗${NC}"
    echo -e "${CYAN}║${NC}       ${BLUE}CTF VPN Monitor${NC} - Durum             ${CYAN}║${NC}"
    echo -e "${CYAN}╚════════════════════════════════════════════════════╝${NC}"
    echo ""
    
    if [ -n "$vpn_ip" ]; then
        echo -e " 🔒 ${YELLOW}VPN IP:${NC}    ${GREEN}$vpn_ip${NC}"
    else
        echo -e " 🔒 ${YELLOW}VPN IP:${NC}    ${RED}Bağlı değil${NC}"
    fi
    
    if [ -n "$local_ip" ]; then
        echo -e " 💻 ${YELLOW}Local IP:${NC}  ${GREEN}$local_ip${NC}"
    else
        echo -e " 💻 ${YELLOW}Local IP:${NC}  ${RED}Bulunamadı${NC}"
    fi
    
    if [ -n "$target_ip" ]; then
        echo -e " 🎯 ${YELLOW}Target IP:${NC} ${CYAN}$target_ip${NC}"
    else
        echo -e " 🎯 ${YELLOW}Target IP:${NC} ${RED}Ayarlanmadı${NC}"
    fi
    
    echo ""
    
    if pgrep -f "ctf_vpn_overlay.py" > /dev/null; then
        echo -e " ${GREEN}● Overlay çalışıyor${NC}"
    else
        echo -e " ${RED}○ Overlay çalışmıyor${NC}"
        echo -e " ${YELLOW}  Başlatmak için: $0 overlay${NC}"
    fi
    echo ""
}

start_overlay() {
    if pgrep -f "ctf_vpn_overlay.py" > /dev/null; then
        echo -e "${YELLOW}⚠ Overlay zaten çalışıyor!${NC}"
        echo -e "Durdurmak için: ${CYAN}$0 stop${NC}"
        exit 0
    fi
    
    if [ ! -f "$OVERLAY_SCRIPT" ]; then
        echo -e "${RED}✗ Overlay scripti bulunamadı: $OVERLAY_SCRIPT${NC}"
        exit 1
    fi
    
    echo -e "${GREEN}▶ CTF VPN Overlay başlatılıyor...${NC}"
    
    if ! command -v python3 &> /dev/null; then
        echo -e "${RED}✗ Python3 bulunamadı!${NC}"
        exit 1
    fi
    
    nohup python3 "$OVERLAY_SCRIPT" > /tmp/ctf_vpn_monitor.log 2>&1 &
    local pid=$!
    
    sleep 2
    
    if pgrep -f "ctf_vpn_overlay.py" > /dev/null; then
        echo -e "${GREEN}✓ Overlay başarıyla başlatıldı! (PID: $pid)${NC}"
        echo -e "${CYAN}ℹ IP bilgileri ekranın üst ortasında görünecek${NC}"
        echo -e "${CYAN}ℹ Sağ tık: Menü | Sol tık: Bildirim${NC}"
    else
        echo -e "${RED}✗ Overlay başlatılamadı!${NC}"
        echo -e "${YELLOW}Log: cat /tmp/ctf_vpn_monitor.log${NC}"
        exit 1
    fi
}

stop_overlay() {
    if ! pgrep -f "ctf_vpn_overlay.py" > /dev/null; then
        echo -e "${YELLOW}⚠ Overlay zaten çalışmıyor${NC}"
        exit 0
    fi
    
    echo -e "${YELLOW}◼ Overlay durduruluyor...${NC}"
    pkill -f "ctf_vpn_overlay.py"
    
    sleep 1
    
    if ! pgrep -f "ctf_vpn_overlay.py" > /dev/null; then
        echo -e "${GREEN}✓ Overlay durduruldu${NC}"
    else
        echo -e "${RED}✗ Durdurma başarısız, zorla kapatılıyor...${NC}"
        pkill -9 -f "ctf_vpn_overlay.py"
    fi
}

restart_overlay() {
    echo -e "${CYAN}↻ Overlay yeniden başlatılıyor...${NC}"
    stop_overlay
    sleep 1
    start_overlay
}

install_requirements() {
    echo -e "${CYAN}╔════════════════════════════════════════════════════╗${NC}"
    echo -e "${CYAN}║${NC}       ${BLUE}CTF VPN Monitor${NC} - Kurulum           ${CYAN}║${NC}"
    echo -e "${CYAN}╚════════════════════════════════════════════════════╝${NC}"
    echo ""
    
    echo -e "${YELLOW}Gerekli paketler kontrol ediliyor...${NC}"
    echo ""
    
    local packages_to_install=()
    
    if ! command -v python3 &> /dev/null; then
        echo -e "${RED}✗ Python3 bulunamadı${NC}"
        packages_to_install+=("python3")
    else
        echo -e "${GREEN}✓ Python3 kurulu${NC}"
    fi
    
    if ! python3 -c "import gi" 2>/dev/null; then
        echo -e "${RED}✗ python3-gi bulunamadı${NC}"
        packages_to_install+=("python3-gi")
    else
        echo -e "${GREEN}✓ python3-gi kurulu${NC}"
    fi
    
    if ! command -v xclip &> /dev/null; then
        echo -e "${YELLOW}○ xclip bulunamadı (opsiyonel)${NC}"
        packages_to_install+=("xclip")
    else
        echo -e "${GREEN}✓ xclip kurulu${NC}"
    fi
    
    if ! command -v notify-send &> /dev/null; then
        echo -e "${YELLOW}○ notify-send bulunamadı (opsiyonel)${NC}"
        packages_to_install+=("libnotify-bin")
    else
        echo -e "${GREEN}✓ notify-send kurulu${NC}"
    fi
    
    echo ""
    
    if [ ${#packages_to_install[@]} -gt 0 ]; then
        echo -e "${YELLOW}Eksik paketler: ${packages_to_install[*]}${NC}"
        echo ""
        
        if [ "$EUID" -eq 0 ]; then
            apt-get update
            apt-get install -y "${packages_to_install[@]}"
        else
            echo -e "${CYAN}Sudo yetkisi gerekiyor...${NC}"
            sudo apt-get update
            sudo apt-get install -y "${packages_to_install[@]}"
        fi
        
        echo ""
        echo -e "${GREEN}✓ Kurulum tamamlandı!${NC}"
    else
        echo -e "${GREEN}✓ Tüm paketler kurulu!${NC}"
    fi
    
    echo ""
    echo -e "${CYAN}Overlay'i başlatmak için: ${YELLOW}$0 overlay${NC}"
}

# Ana komut işleyici
case "$1" in
    overlay)
        start_overlay
        ;;
    stop)
        stop_overlay
        ;;
    restart)
        restart_overlay
        ;;
    target)
        case "$2" in
            -u)
                if [ -z "$3" ]; then
                    echo -e "${RED}✗ Hata: IP adresi belirtilmedi!${NC}"
                    echo "Kullanım: $0 target -u <IP>"
                    exit 1
                fi
                set_target_ip "$3"
                ;;
            --clear)
                clear_target_ip
                ;;
            *)
                echo -e "${RED}✗ Hata: Geçersiz parametre!${NC}"
                echo "Kullanım: $0 target -u <IP>  veya  $0 target --clear"
                exit 1
                ;;
        esac
        ;;
    status)
        show_status
        ;;
    install)
        install_requirements
        ;;
    help|--help|-h|"")
        show_help
        ;;
    *)
        echo -e "${RED}✗ Geçersiz komut: $1${NC}"
        echo ""
        show_help
        exit 1
        ;;
esac
