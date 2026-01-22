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
        self.window.set_decorated(False)  # Çerçevesiz
        self.window.set_keep_above(True)  # Her zaman üstte
        self.window.set_accept_focus(False)  # Focus almaz
        self.window.set_skip_taskbar_hint(True)  # Taskbar'da görünmez
        self.window.set_skip_pager_hint(True)  # Pager'da görünmez
        
        # Tüm masaüstlerinde göster
        self.window.stick()
        
        # Window type hints
        self.window.set_type_hint(Gdk.WindowTypeHint.DOCK)
        
        # Pencereyi tıklanabilir yap ama arkasındaki pencereler de tıklanabilir olsun
        self.window.set_app_paintable(True)
        
        # Arka planı yarı şeffaf yap
        screen = self.window.get_screen()
        visual = screen.get_rgba_visual()
        if visual:
            self.window.set_visual(visual)
        
        # CSS ile stil
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
        
        # Main container
        vbox = Gtk.Box(orientation=Gtk.Orientation.VERTICAL, spacing=0)
        
        # Info box
        hbox = Gtk.Box(orientation=Gtk.Orientation.HORIZONTAL, spacing=0)
        
        # VPN Label
        self.vpn_label = Gtk.Label()
        self.vpn_label.set_markup('<span foreground="#00ff00">● VPN: --</span>')
        hbox.pack_start(self.vpn_label, False, False, 0)
        
        # Separator
        sep1 = Gtk.Label(label="│")
        sep1.get_style_context().add_class("separator")
        hbox.pack_start(sep1, False, False, 4)
        
        # Local Label
        self.local_label = Gtk.Label()
        self.local_label.set_markup('<span foreground="#00aaff">■ Local: --</span>')
        hbox.pack_start(self.local_label, False, False, 0)
        
        # Separator
        sep2 = Gtk.Label(label="│")
        sep2.get_style_context().add_class("separator")
        hbox.pack_start(sep2, False, False, 4)
        
        # Target Label
        self.target_label = Gtk.Label()
        self.target_label.set_markup('<span foreground="#ffaa00">▸ Target: --</span>')
        hbox.pack_start(self.target_label, False, False, 0)
        
        vbox.pack_start(hbox, True, True, 0)
        
        # Event box for clicks
        event_box = Gtk.EventBox()
        event_box.add(vbox)
        event_box.connect("button-press-event", self.on_click)
        event_box.connect("enter-notify-event", self.on_mouse_enter)
        event_box.connect("leave-notify-event", self.on_mouse_leave)
        
        self.window.add(event_box)
        
        # İlk pozisyon
        self.window.show_all()
        GLib.idle_add(self.position_window)
        
        # Menü
        self.create_menu()
        
        # Güncelleme
        self.update_info()
        GLib.timeout_add_seconds(5, self.update_info)
        
        # Ekran değişikliklerini takip et
        screen.connect("size-changed", lambda s: self.position_window())
        
        print("✓ CTF VPN Overlay başlatıldı!")
        print("  Ekranın üst ortasında görmelisiniz")
        print("  Sağ tık: Menü | Sol tık: Bildirim")
    
    def position_window(self):
        """Pencereyi orta üste yerleştir"""
        # Pencere boyutunu zorla hesapla
        self.window.realize()
        self.window.get_preferred_width()
        self.window.get_preferred_height()
        
        # Ekran bilgisi
        screen = self.window.get_screen()
        monitor_num = screen.get_primary_monitor()
        monitor = screen.get_monitor_geometry(monitor_num)
        
        # Pencere boyutu
        width = self.window.get_allocated_width()
        height = self.window.get_allocated_height()
        
        # Orta üst (yatayda ortala, yukarıdan 5 pixel)
        x = monitor.x + (monitor.width - width) // 2
        y = monitor.y + 5
        
        self.window.move(x, y)
        
        return False
    
    def on_mouse_enter(self, widget, event):
        """Fare üzerine gelince biraz daha opak yap"""
        pass
    
    def on_mouse_leave(self, widget, event):
        """Fare ayrılınca geri al"""
        pass
    
    def create_menu(self):
        """Sağ tıklama menüsü"""
        self.menu = Gtk.Menu()
        
        # Başlık
        title = Gtk.MenuItem(label="═══ CTF VPN Monitor ═══")
        title.set_sensitive(False)
        self.menu.append(title)
        
        self.menu.append(Gtk.SeparatorMenuItem())
        
        # IP'leri kopyala
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
        
        # Hedef IP ayarla
        set_target = Gtk.MenuItem(label="⚙️  Hedef IP Ayarla...")
        set_target.connect("activate", self.set_target_ip)
        self.menu.append(set_target)
        
        # Hedef IP temizle
        clear_target = Gtk.MenuItem(label="🗑️  Hedef IP Temizle")
        clear_target.connect("activate", self.clear_target_ip)
        self.menu.append(clear_target)
        
        self.menu.append(Gtk.SeparatorMenuItem())
        
        # Yenile
        refresh = Gtk.MenuItem(label="🔄 Yenile")
        refresh.connect("activate", self.force_update)
        self.menu.append(refresh)
        
        # Pozisyonu düzelt
        fix_pos = Gtk.MenuItem(label="📍 Pozisyonu Düzelt")
        fix_pos.connect("activate", lambda w: self.position_window())
        self.menu.append(fix_pos)
        
        self.menu.append(Gtk.SeparatorMenuItem())
        
        # Çıkış
        quit_item = Gtk.MenuItem(label="❌ Çıkış")
        quit_item.connect("activate", self.quit)
        self.menu.append(quit_item)
        
        self.menu.show_all()
    
    def on_click(self, widget, event):
        """Tıklama olayları"""
        if event.button == 3:  # Sağ tık
            self.menu.popup(None, None, None, None, event.button, event.time)
            return True
        elif event.button == 1:  # Sol tık
            self.show_status_notification()
            return True
        return False
    
    def show_status_notification(self):
        """Durum bildirimi"""
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
        """IP'yi panoya kopyala"""
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
        """Config yükle"""
        try:
            if self.config_file.exists():
                with open(self.config_file, 'r') as f:
                    config = json.load(f)
                    return config.get('target_ip', '')
        except:
            pass
        return ''
    
    def save_config(self):
        """Config kaydet"""
        try:
            with open(self.config_file, 'w') as f:
                json.dump({'target_ip': self.target_ip}, f)
        except:
            pass
    
    def get_vpn_ip(self):
        """VPN IP al"""
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
        """Local IP al"""
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
        """Bilgileri güncelle"""
        vpn_ip = self.get_vpn_ip()
        local_ip = self.get_local_ip()
        
        # VPN
        if vpn_ip:
            self.vpn_label.set_markup(f'<span foreground="#00ff00">● VPN: {vpn_ip}</span>')
        else:
            self.vpn_label.set_markup(f'<span foreground="#ff3333">● VPN: Bağlı değil</span>')
        
        # Local
        if local_ip:
            self.local_label.set_markup(f'<span foreground="#00aaff">■ Local: {local_ip}</span>')
        else:
            self.local_label.set_markup(f'<span foreground="#666666">■ Local: --</span>')
        
        # Target
        if self.target_ip:
            self.target_label.set_markup(f'<span foreground="#ffaa00">▸ Target: {self.target_ip}</span>')
        else:
            self.target_label.set_markup(f'<span foreground="#666666">▸ Target: --</span>')
        
        # Pozisyonu kontrol et
        GLib.idle_add(self.position_window)
        
        return True
    
    def force_update(self, widget=None):
        """Manuel güncelleme"""
        self.update_info()
        subprocess.run(['notify-send', '-t', '1000', 'CTF VPN Monitor', 'Güncellendi'],
                      timeout=2, stderr=subprocess.DEVNULL)
    
    def set_target_ip(self, widget):
        """Hedef IP ayarla"""
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
        """Hedef IP temizle"""
        self.target_ip = ''
        self.save_config()
        self.update_info()
        subprocess.run(['notify-send', '-t', '2000', 'Hedef IP Temizlendi', 'Target IP sıfırlandı'],
                      timeout=2, stderr=subprocess.DEVNULL)
        print("✓ Hedef IP temizlendi")
    
    def quit(self, widget):
        """Çıkış"""
        print("CTF VPN Overlay kapatılıyor...")
        Gtk.main_quit()

def main():
    if os.geteuid() == 0:
        print("⚠ Root olarak çalıştırmayın!")
    
    overlay = CTFVPNOverlay()
    
    try:
        Gtk.main()
    except KeyboardInterrupt:
        print("\\nKapatılıyor...")

if __name__ == "__main__":
    main()
