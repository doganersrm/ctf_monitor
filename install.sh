#!/bin/bash
# CTF VPN Monitor - One-Click Installer
# Kullanım: curl -sSL https://raw.githubusercontent.com/doganersrm/ctf_monitor/main/install.sh | bash

set -e

# Renkler
RED='\033[0;31m'
GREEN='\033[0;32m'
YELLOW='\033[1;33m'
BLUE='\033[0;34m'
CYAN='\033[0;36m'
NC='\033[0m'

INSTALL_DIR="$HOME/.ctf-vpn-monitor"
BIN_DIR="$HOME/.local/bin"
CONFIG_FILE="$HOME/.ctf_vpn_config.json"

banner() {
    if [ -t 1 ]; then clear; fi
    echo -e "${CYAN}"
    cat << "EOF"
╔════════════════════════════════════════════════════╗
║                                                    ║
║        CTF VPN Monitor - Overlay Edition          ║
║              One-Click Installer                  ║
║                                                    ║
╚════════════════════════════════════════════════════╝
EOF
    echo -e "${NC}"
}

check_root() {
    if [ "$EUID" -eq 0 ]; then
        echo -e "${RED}Kurulumu masaüstü oturumunu açan normal kullanıcıyla çalıştırın (sudo kullanmayın).${NC}" >&2
        exit 1
    fi
}

check_dependencies() {
    echo -e "${YELLOW}📦 Gerekli paketler kontrol ediliyor...${NC}"
    echo ""
    
    local packages_to_install=()
    
    if ! command -v python3 &> /dev/null; then
        echo -e "${RED}✗ Python3 bulunamadı${NC}"
        packages_to_install+=("python3")
    else
        echo -e "${GREEN}✓ Python3 kurulu${NC}"
    fi
    
    if ! python3 -c "import gi; gi.require_version('Gtk', '3.0'); from gi.repository import Gtk" 2>/dev/null; then
        echo -e "${RED}✗ python3-gi bulunamadı${NC}"
        packages_to_install+=("python3-gi")
        packages_to_install+=("gir1.2-gtk-3.0")
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
        if ! command -v apt-get >/dev/null; then
            echo -e "${RED}Eksik paketlerin otomatik kurulumu için apt-get gerekli (Debian/Ubuntu/Kali).${NC}" >&2
            exit 1
        fi
        echo -e "${YELLOW}⚠ Eksik paketler: ${packages_to_install[*]}${NC}"
        echo ""
        echo -e "${CYAN}Kurmak için sudo yetkisi gerekiyor...${NC}"
        sudo apt-get update
        sudo apt-get install -y "${packages_to_install[@]}"
        python3 -c "import gi; gi.require_version('Gtk', '3.0'); from gi.repository import Gtk" || { echo 'GTK3 Python modülü yüklenemedi.' >&2; exit 1; }
        echo ""
        echo -e "${GREEN}✓ Paketler kuruldu!${NC}"
    else
        echo -e "${GREEN}✓ Tüm paketler mevcut!${NC}"
    fi
    echo ""
}

create_directories() {
    echo -e "${CYAN}📁 Dizinler oluşturuluyor...${NC}"
    mkdir -p "$INSTALL_DIR"
    mkdir -p "$BIN_DIR"
    echo -e "${GREEN}✓ Dizinler hazır${NC}"
    echo ""
}

install_overlay_script() {
    echo -e "${CYAN}📝 Overlay scripti yükleniyor...${NC}"
    
    cat > "$INSTALL_DIR/ctf_vpn_overlay.py" << 'OVERLAY_EOF'
#!/usr/bin/env python3
"""
CTF VPN Monitor - Always-on-top Overlay Edition
Ekranın sağ üst köşesinde her zaman görünür
"""

import gi
gi.require_version('Gtk', '3.0')
from gi.repository import Gtk, GLib, Gdk
import subprocess
import re
import os
import json
from pathlib import Path

class CTFVPNOverlay:
    def __init__(self):
        self.config_file = Path.home() / '.ctf_vpn_config.json'
        self.target_ip = self.load_config()
        
        # Ana pencere oluştur
        self.window = Gtk.Window()
        self.window.set_decorated(False)
        self.window.set_keep_above(True)
        self.window.set_accept_focus(False)
        self.window.set_skip_taskbar_hint(True)
        self.window.set_skip_pager_hint(True)
        self.window.stick()
        self.window.set_type_hint(Gdk.WindowTypeHint.DOCK)
        self.window.set_app_paintable(True)
        
        screen = self.window.get_screen()
        visual = screen.get_rgba_visual()
        if visual:
            self.window.set_visual(visual)
        
        css_provider = Gtk.CssProvider()
        css_provider.load_from_data(b"""
            window {
                background-color: rgba(0, 0, 0, 0);
            }
            box {
                padding: 4px 10px;
            }
            label {
                color: #ffffff;
                font-family: "Monospace", "Courier New", monospace;
                font-size: 14px;
                font-weight: bold;
                text-shadow: 2px 2px 4px rgba(0, 0, 0, 0.9);
            }
            label.separator {
                color: #888888;
                padding: 0px 6px;
            }
        """)
        
        style_context = Gtk.StyleContext()
        style_context.add_provider_for_screen(
            screen,
            css_provider,
            Gtk.STYLE_PROVIDER_PRIORITY_APPLICATION
        )
        
        vbox = Gtk.Box(orientation=Gtk.Orientation.VERTICAL, spacing=0)
        hbox = Gtk.Box(orientation=Gtk.Orientation.HORIZONTAL, spacing=0)
        
        self.vpn_label = Gtk.Label()
        self.vpn_label.set_markup('<span foreground="#00ff00">● VPN: --</span>')
        hbox.pack_start(self.vpn_label, False, False, 0)
        
        sep1 = Gtk.Label(label="│")
        sep1.get_style_context().add_class("separator")
        hbox.pack_start(sep1, False, False, 4)
        
        self.local_label = Gtk.Label()
        self.local_label.set_markup('<span foreground="#00aaff">■ Local: --</span>')
        hbox.pack_start(self.local_label, False, False, 0)
        
        sep2 = Gtk.Label(label="│")
        sep2.get_style_context().add_class("separator")
        hbox.pack_start(sep2, False, False, 4)
        
        self.target_label = Gtk.Label()
        self.target_label.set_markup('<span foreground="#ffaa00">▸ Target: --</span>')
        hbox.pack_start(self.target_label, False, False, 0)
        
        vbox.pack_start(hbox, True, True, 0)
        
        event_box = Gtk.EventBox()
        event_box.add(vbox)
        event_box.connect("button-press-event", self.on_click)
        
        self.window.add(event_box)
        self.window.show_all()
        GLib.idle_add(self.position_window)
        
        self.create_menu()
        self.update_info()
        GLib.timeout_add_seconds(5, self.update_info)
        screen.connect("size-changed", lambda s: self.position_window())
        
        print("✓ CTF VPN Overlay başlatıldı!")
        print("  Ekranın üst ortasında görmelisiniz")
        print("  Sağ tık: Menü | Sol tık: Bildirim")
    
    def position_window(self):
        self.window.realize()
        self.window.get_preferred_width()
        self.window.get_preferred_height()
        
        screen = self.window.get_screen()
        monitor_num = screen.get_primary_monitor()
        monitor = screen.get_monitor_geometry(monitor_num)
        
        width = self.window.get_allocated_width()
        height = self.window.get_allocated_height()
        
        x = monitor.x + (monitor.width - width) // 2
        y = monitor.y + 5
        
        self.window.move(x, y)
        return False
    
    def create_menu(self):
        self.menu = Gtk.Menu()
        
        title = Gtk.MenuItem(label="═══ CTF VPN Monitor ═══")
        title.set_sensitive(False)
        self.menu.append(title)
        self.menu.append(Gtk.SeparatorMenuItem())
        
        copy_menu = Gtk.MenuItem(label="📋 Kopyala")
        copy_submenu = Gtk.Menu()
        
        copy_vpn = Gtk.MenuItem(label="VPN IP")
        copy_vpn.connect("activate", lambda w: self.copy_to_clipboard('vpn'))
        copy_submenu.append(copy_vpn)
        
        copy_local = Gtk.MenuItem(label="Local IP")
        copy_local.connect("activate", lambda w: self.copy_to_clipboard('local'))
        copy_submenu.append(copy_local)
        
        copy_target = Gtk.MenuItem(label="Target IP")
        copy_target.connect("activate", lambda w: self.copy_to_clipboard('target'))
        copy_submenu.append(copy_target)
        
        copy_menu.set_submenu(copy_submenu)
        self.menu.append(copy_menu)
        self.menu.append(Gtk.SeparatorMenuItem())
        
        set_target = Gtk.MenuItem(label="⚙️  Hedef IP Ayarla...")
        set_target.connect("activate", self.set_target_ip)
        self.menu.append(set_target)
        
        clear_target = Gtk.MenuItem(label="🗑️  Hedef IP Temizle")
        clear_target.connect("activate", self.clear_target_ip)
        self.menu.append(clear_target)
        
        self.menu.append(Gtk.SeparatorMenuItem())
        
        refresh = Gtk.MenuItem(label="🔄 Yenile")
        refresh.connect("activate", self.force_update)
        self.menu.append(refresh)
        
        fix_pos = Gtk.MenuItem(label="📍 Pozisyonu Düzelt")
        fix_pos.connect("activate", lambda w: self.position_window())
        self.menu.append(fix_pos)
        
        self.menu.append(Gtk.SeparatorMenuItem())
        
        quit_item = Gtk.MenuItem(label="❌ Çıkış")
        quit_item.connect("activate", self.quit)
        self.menu.append(quit_item)
        
        self.menu.show_all()
    
    def on_click(self, widget, event):
        if event.button == 3:
            self.menu.popup(None, None, None, None, event.button, event.time)
            return True
        elif event.button == 1:
            self.show_status_notification()
            return True
        return False
    
    def show_status_notification(self):
        vpn_ip = self.get_vpn_ip()
        local_ip = self.get_local_ip()
        
        lines = []
        if vpn_ip:
            lines.append(f"🔒 VPN: {vpn_ip}")
        else:
            lines.append("🔒 VPN: Bağlı değil")
        
        if local_ip:
            lines.append(f"💻 Local: {local_ip}")
        
        if self.target_ip:
            lines.append(f"🎯 Target: {self.target_ip}")
        
        try:
            message = "\\n".join(lines)
            subprocess.run(['notify-send', '-t', '3000', 'CTF VPN Monitor', message], 
                         timeout=2, stderr=subprocess.DEVNULL)
        except:
            pass
    
    def copy_to_clipboard(self, ip_type):
        ip = None
        if ip_type == 'vpn':
            ip = self.get_vpn_ip()
        elif ip_type == 'local':
            ip = self.get_local_ip()
        elif ip_type == 'target':
            ip = self.target_ip
        
        if ip:
            try:
                subprocess.run(['xclip', '-selection', 'clipboard'], 
                             input=ip.encode(), timeout=2)
                subprocess.run(['notify-send', '-t', '2000', 'Kopyalandı', f'{ip_type.upper()}: {ip}'],
                             timeout=2, stderr=subprocess.DEVNULL)
                print(f"✓ {ip} panoya kopyalandı")
            except:
                pass
    
    def load_config(self):
        try:
            if self.config_file.exists():
                with open(self.config_file, 'r') as f:
                    config = json.load(f)
                    return config.get('target_ip', '')
        except:
            pass
        return ''
    
    def save_config(self):
        try:
            with open(self.config_file, 'w') as f:
                json.dump({'target_ip': self.target_ip}, f)
        except:
            pass
    
    def get_vpn_ip(self):
        try:
            result = subprocess.run(
                ['ip', 'addr', 'show', 'tun0'],
                capture_output=True,
                text=True,
                timeout=2
            )
            if result.returncode == 0:
                match = re.search(r'inet (\d+\.\d+\.\d+\.\d+)', result.stdout)
                if match:
                    return match.group(1)
        except:
            pass
        return None
    
    def get_local_ip(self):
        interfaces = ['eth0', 'wlan0', 'ens33', 'enp0s3']
        
        for iface in interfaces:
            try:
                result = subprocess.run(
                    ['ip', 'addr', 'show', iface],
                    capture_output=True,
                    text=True,
                    timeout=2
                )
                if result.returncode == 0:
                    match = re.search(r'inet (\d+\.\d+\.\d+\.\d+)', result.stdout)
                    if match:
                        return match.group(1)
            except:
                continue
        return None
    
    def update_info(self):
        vpn_ip = self.get_vpn_ip()
        local_ip = self.get_local_ip()
        
        if vpn_ip:
            self.vpn_label.set_markup(f'<span foreground="#00ff00">● VPN: {vpn_ip}</span>')
        else:
            self.vpn_label.set_markup(f'<span foreground="#ff3333">● VPN: Bağlı değil</span>')
        
        if local_ip:
            self.local_label.set_markup(f'<span foreground="#00aaff">■ Local: {local_ip}</span>')
        else:
            self.local_label.set_markup(f'<span foreground="#666666">■ Local: --</span>')
        
        if self.target_ip:
            self.target_label.set_markup(f'<span foreground="#ffaa00">▸ Target: {self.target_ip}</span>')
        else:
            self.target_label.set_markup(f'<span foreground="#666666">▸ Target: --</span>')
        
        GLib.idle_add(self.position_window)
        return True
    
    def force_update(self, widget=None):
        self.update_info()
        subprocess.run(['notify-send', '-t', '1000', 'CTF VPN Monitor', 'Güncellendi'],
                      timeout=2, stderr=subprocess.DEVNULL)
    
    def set_target_ip(self, widget):
        dialog = Gtk.Dialog(
            title="Hedef IP Ayarla",
            parent=self.window,
            flags=0
        )
        dialog.add_buttons(
            Gtk.STOCK_CANCEL, Gtk.ResponseType.CANCEL,
            Gtk.STOCK_OK, Gtk.ResponseType.OK
        )
        
        dialog.set_default_size(350, 120)
        dialog.set_keep_above(True)
        
        content = dialog.get_content_area()
        content.set_spacing(10)
        content.set_border_width(15)
        
        label = Gtk.Label()
        label.set_markup("<b>Hedef IP adresini girin:</b>")
        content.add(label)
        
        entry = Gtk.Entry()
        entry.set_text(self.target_ip)
        entry.set_width_chars(20)
        entry.set_activates_default(True)
        content.add(entry)
        
        dialog.set_default_response(Gtk.ResponseType.OK)
        dialog.show_all()
        
        response = dialog.run()
        
        if response == Gtk.ResponseType.OK:
            new_ip = entry.get_text().strip()
            if re.match(r'^\d{1,3}\.\d{1,3}\.\d{1,3}\.\d{1,3}$', new_ip):
                self.target_ip = new_ip
                self.save_config()
                self.update_info()
                subprocess.run(['notify-send', '-t', '2000', 'Hedef IP Ayarlandı', new_ip],
                              timeout=2, stderr=subprocess.DEVNULL)
                print(f"✓ Hedef IP: {new_ip}")
            else:
                error = Gtk.MessageDialog(
                    parent=dialog,
                    flags=0,
                    message_type=Gtk.MessageType.ERROR,
                    buttons=Gtk.ButtonsType.OK,
                    text="Geçersiz IP formatı!"
                )
                error.format_secondary_text("Örnek: 10.10.11.202")
                error.run()
                error.destroy()
        
        dialog.destroy()
    
    def clear_target_ip(self, widget):
        self.target_ip = ''
        self.save_config()
        self.update_info()
        subprocess.run(['notify-send', '-t', '2000', 'Hedef IP Temizlendi', 'Target IP sıfırlandı'],
                      timeout=2, stderr=subprocess.DEVNULL)
        print("✓ Hedef IP temizlendi")
    
    def quit(self, widget):
        print("CTF VPN Overlay kapatılıyor...")
        Gtk.main_quit()

def main():
    if os.geteuid() == 0:
        print("⚠ Root olarak çalışıyorsunuz!")
        print("  Not: Overlay root olarak da çalışır ama bazı özellikler kısıtlı olabilir.")
    
    overlay = CTFVPNOverlay()
    
    try:
        Gtk.main()
    except KeyboardInterrupt:
        print("\\nKapatılıyor...")

if __name__ == "__main__":
    main()
OVERLAY_EOF

    chmod +x "$INSTALL_DIR/ctf_vpn_overlay.py"
    echo -e "${GREEN}✓ Overlay scripti yüklendi${NC}"
    echo ""
}

install_cli_wrapper() {
    echo -e "${CYAN}📝 CLI wrapper yükleniyor...${NC}"
    
    cat > "$BIN_DIR/ctfmon" << 'CLI_EOF'
#!/bin/bash
# CTF VPN Monitor - CLI Wrapper

INSTALL_DIR="$HOME/.ctf-vpn-monitor"
OVERLAY_SCRIPT="$INSTALL_DIR/ctf_vpn_overlay.py"
CONFIG_FILE="$HOME/.ctf_vpn_config.json"

RED='\033[0;31m'
GREEN='\033[0;32m'
YELLOW='\033[1;33m'
BLUE='\033[0;34m'
CYAN='\033[0;36m'
NC='\033[0m'

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

case "$1" in
    start|overlay)
        if pgrep -f "ctf_vpn_overlay.py" > /dev/null; then
            echo -e "${YELLOW}⚠ Overlay zaten çalışıyor!${NC}"
            exit 0
        fi
        echo -e "${GREEN}▶ CTF VPN Overlay başlatılıyor...${NC}"
        nohup /usr/bin/python3 "$OVERLAY_SCRIPT" > "$INSTALL_DIR/ctf_vpn_monitor.log" 2>&1 &
        sleep 2
        if pgrep -f "ctf_vpn_overlay.py" > /dev/null; then
            echo -e "${GREEN}✓ Overlay başlatıldı!${NC}"
        else
            echo -e "${RED}✗ Başlatılamadı! Log: $INSTALL_DIR/ctf_vpn_monitor.log${NC}"
            exit 1
        fi
        ;;
    stop)
        if ! pgrep -f "ctf_vpn_overlay.py" > /dev/null; then
            echo -e "${YELLOW}⚠ Overlay çalışmıyor${NC}"
            exit 0
        fi
        echo -e "${YELLOW}◼ Overlay durduruluyor...${NC}"
        pkill -f "ctf_vpn_overlay.py"
        sleep 1
        echo -e "${GREEN}✓ Overlay durduruldu${NC}"
        ;;
    restart)
        $0 stop
        sleep 1
        $0 start
        ;;
    target)
        if [ "$2" = "-u" ] && [ -n "$3" ]; then
            echo "{\"target_ip\": \"$3\"}" > "$CONFIG_FILE"
            echo -e "${GREEN}✓ Hedef IP: ${YELLOW}$3${NC}"
        elif [ "$2" = "--clear" ]; then
            echo "{\"target_ip\": \"\"}" > "$CONFIG_FILE"
            echo -e "${GREEN}✓ Hedef IP temizlendi${NC}"
        else
            echo -e "${RED}✗ Kullanım: ctfmon target -u <IP> | --clear${NC}"
        fi
        ;;
    status)
        vpn_ip=$(get_vpn_ip)
        local_ip=$(get_local_ip)
        target_ip=$(get_target_ip)
        
        echo -e "${CYAN}╔════════════════════════════════════════╗${NC}"
        echo -e "${CYAN}║${NC}    ${BLUE}CTF VPN Monitor${NC} - Durum     ${CYAN}║${NC}"
        echo -e "${CYAN}╚════════════════════════════════════════╝${NC}"
        echo ""
        [ -n "$vpn_ip" ] && echo -e " 🔒 VPN:    ${GREEN}$vpn_ip${NC}" || echo -e " 🔒 VPN:    ${RED}Bağlı değil${NC}"
        [ -n "$local_ip" ] && echo -e " 💻 Local:  ${GREEN}$local_ip${NC}" || echo -e " 💻 Local:  ${RED}--${NC}"
        [ -n "$target_ip" ] && echo -e " 🎯 Target: ${CYAN}$target_ip${NC}" || echo -e " 🎯 Target: ${RED}--${NC}"
        echo ""
        pgrep -f "ctf_vpn_overlay.py" > /dev/null && echo -e " ${GREEN}● Overlay çalışıyor${NC}" || echo -e " ${RED}○ Overlay çalışmıyor${NC}"
        echo ""
        ;;
    update)
        echo -e "${CYAN}🔄 Güncelleme kontrol ediliyor...${NC}"
        curl -sSL https://raw.githubusercontent.com/doganersrm/ctf_monitor/main/install.sh | bash
        ;;
    uninstall)
        echo -e "${YELLOW}🗑️  Kaldırılıyor...${NC}"
        $0 stop 2>/dev/null
        rm -rf "$INSTALL_DIR"
        rm -f "$BIN_DIR/ctfmon"
        rm -f "$HOME/.config/autostart/ctf-vpn-monitor.desktop"
        rm -f "$CONFIG_FILE"
        echo -e "${GREEN}✓ Kaldırıldı${NC}"
        ;;
    *)
        echo -e "${CYAN}CTF VPN Monitor${NC} - Kullanım:"
        echo ""
        echo "  ctfmon start              - Overlay'i başlat"
        echo "  ctfmon stop               - Overlay'i durdur"
        echo "  ctfmon restart            - Yeniden başlat"
        echo "  ctfmon target -u <IP>     - Hedef IP ayarla"
        echo "  ctfmon target --clear     - Hedef IP temizle"
        echo "  ctfmon status             - Durum göster"
        echo "  ctfmon update             - Güncelle"
        echo "  ctfmon uninstall          - Kaldır"
        ;;
esac
CLI_EOF

    chmod +x "$BIN_DIR/ctfmon"
    echo -e "${GREEN}✓ CLI wrapper yüklendi${NC}"
    echo ""
}

setup_path() {
    echo -e "${CYAN}🔧 PATH ayarlanıyor...${NC}"
    
    # .bashrc için
    if [ -f "$HOME/.bashrc" ] && ! grep -q "$BIN_DIR" "$HOME/.bashrc"; then
        echo "" >> "$HOME/.bashrc"
        echo "# CTF VPN Monitor" >> "$HOME/.bashrc"
        echo "export PATH=\"\$PATH:$BIN_DIR\"" >> "$HOME/.bashrc"
    fi
    
    # .zshrc için
    if [ -f "$HOME/.zshrc" ] && ! grep -q "$BIN_DIR" "$HOME/.zshrc"; then
        echo "" >> "$HOME/.zshrc"
        echo "# CTF VPN Monitor" >> "$HOME/.zshrc"
        echo "export PATH=\"\$PATH:$BIN_DIR\"" >> "$HOME/.zshrc"
    fi
    
    # Şu anki session için
    export PATH="$PATH:$BIN_DIR"
    
    echo -e "${GREEN}✓ PATH ayarlandı${NC}"
    echo ""
}

create_version_file() {
    echo "1.0.0" > "$INSTALL_DIR/VERSION"
}

setup_autostart() {
    local desktop_dir="$HOME/.config/autostart"
    mkdir -p "$desktop_dir"
    cat > "$desktop_dir/ctf-vpn-monitor.desktop" <<EOF
[Desktop Entry]
Type=Application
Name=CTF VPN Monitor
Comment=VPN and target IP overlay
Exec=$BIN_DIR/ctfmon start
Terminal=false
X-GNOME-Autostart-enabled=true
EOF
    echo -e "${GREEN}✓ Oturum açılışında otomatik başlatma ayarlandı${NC}"
}

start_if_graphical() {
    if [ -n "${DISPLAY:-}${WAYLAND_DISPLAY:-}" ]; then
        "$BIN_DIR/ctfmon" restart
    else
        echo -e "${YELLOW}Grafik oturum bulunamadı; overlay sonraki masaüstü oturumunda başlayacak.${NC}"
    fi
}

finish() {
    echo -e "${GREEN}"
    cat << "EOF"
╔════════════════════════════════════════════════════╗
║                                                    ║
║           ✓ Kurulum Tamamlandı!                   ║
║                                                    ║
╚════════════════════════════════════════════════════╝
EOF
    echo -e "${NC}"
    
    echo -e "${CYAN}🚀 Hızlı Başlangıç:${NC}"
    echo ""
    echo -e "  ${YELLOW}# Yeni terminal aç veya:${NC}"
    echo -e "  ${CYAN}source ~/.bashrc${NC}  # veya source ~/.zshrc"
    echo ""
    echo -e "  ${YELLOW}# Overlay'i başlat:${NC}"
    echo -e "  ${CYAN}ctfmon start${NC}"
    echo ""
    echo -e "  ${YELLOW}# Hedef IP ayarla:${NC}"
    echo -e "  ${CYAN}ctfmon target -u 10.10.11.202${NC}"
    echo ""
    echo -e "  ${YELLOW}# Durum:${NC}"
    echo -e "  ${CYAN}ctfmon status${NC}"
    echo ""
    echo -e "${BLUE}Daha fazla bilgi: ctfmon${NC}"
    echo ""
}

# Ana kurulum
main() {
    banner
    check_root
    check_dependencies
    create_directories
    install_overlay_script
    install_cli_wrapper
    setup_path
    create_version_file
    setup_autostart
    start_if_graphical
    finish
}

main
