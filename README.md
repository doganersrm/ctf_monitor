# 🎯 CTF VPN Monitor

Ekranın üstünde her zaman görünen, VPN ve hedef IP bilgilerinizi gösteren overlay aracı.

## ⚡ Tek Komutla Kurulum

```bash
curl -sSL https://raw.githubusercontent.com/YOUR_USERNAME/ctf-vpn-monitor/main/install.sh | bash
```

Veya manuel:

```bash
wget https://raw.githubusercontent.com/YOUR_USERNAME/ctf-vpn-monitor/main/install.sh
chmod +x install.sh
./install.sh
```

## 🚀 Kullanım

```bash
# Yeni terminal aç veya:
source ~/.bashrc  # veya source ~/.zshrc

# Overlay'i başlat
ctfmon start

# Hedef IP ayarla
ctfmon target -u 10.10.11.202

# Durum göster
ctfmon status

# Durdur
ctfmon stop

# Güncelle
ctfmon update

# Kaldır
ctfmon uninstall
```

## 📸 Görünüm

Ekranın üst ortasında:
```
● VPN: 10.10.14.5 │ ■ Local: 192.168.1.100 │ ▸ Target: 10.10.11.202
```

## 🎨 Özellikler

- ✅ **Her zaman üstte** - Diğer pencerelerin üzerinde
- ✅ **Şeffaf arka plan** - Görüşü engellemez
- ✅ **Otomatik güncelleme** - 5 saniyede bir
- ✅ **Tek tıkla kopyalama** - Sağ tık menüsü
- ✅ **Kolay kurulum** - Tek komut
- ✅ **Kolay güncelleme** - `ctfmon update`

## 🖱️ Fare İşlemleri

- **Sol Tık**: Bildirim göster
- **Sağ Tık**: Menü
  - 📋 IP'leri kopyala
  - ⚙️ Hedef IP ayarla
  - 🗑️ Hedef IP temizle
  - 🔄 Yenile
  - 📍 Pozisyonu düzelt
  - ❌ Çıkış

## 📦 Gereksinimler

Otomatik kurulur:
- Python 3
- python3-gi (GTK3)
- xclip (kopyalama için)
- libnotify-bin (bildirimler için)

## 🔧 Sorun Giderme

```bash
# Log kontrol
cat /tmp/ctf_vpn_monitor.log

# Yeniden başlat
ctfmon restart

# Durum kontrol
ctfmon status
```

## 🗂️ Dosya Konumları

- Program: `~/.ctf-vpn-monitor/`
- Config: `~/.ctf_vpn_config.json`
- Binary: `~/.local/bin/ctfmon`
- Log: `/tmp/ctf_vpn_monitor.log`

## 🎯 Örnek Workflow

```bash
# 1. Kurulum
curl -sSL URL | bash
source ~/.bashrc

# 2. Overlay başlat
ctfmon start

# 3. VPN'e bağlan
sudo openvpn lab.ovpn

# 4. Hedef ayarla
ctfmon target -u 10.10.11.202

# 5. Çalış!
# IP'ler ekranın üstünde görünüyor
# Sol tık: bildirim
# Sağ tık: IP kopyala
```

## 📝 Komutlar

| Komut | Açıklama |
|-------|----------|
| `ctfmon start` | Overlay'i başlat |
| `ctfmon stop` | Overlay'i durdur |
| `ctfmon restart` | Yeniden başlat |
| `ctfmon target -u IP` | Hedef IP ayarla |
| `ctfmon target --clear` | Hedef IP temizle |
| `ctfmon status` | Durum göster |
| `ctfmon update` | Güncelle |
| `ctfmon uninstall` | Kaldır |

## 🔄 Güncelleme

```bash
ctfmon update
```

## 🗑️ Kaldırma

```bash
ctfmon uninstall
```

## 📱 Sistem Başlangıcında Çalıştırma

```bash
mkdir -p ~/.config/autostart

cat > ~/.config/autostart/ctf-vpn-monitor.desktop << 'EOF'
[Desktop Entry]
Type=Application
Name=CTF VPN Monitor
Exec=/home/YOUR_USERNAME/.local/bin/ctfmon start
Hidden=false
NoDisplay=false
X-GNOME-Autostart-enabled=true
EOF
```

## 🤝 Katkıda Bulunma

Pull request'ler kabul edilir!

## 📄 Lisans

MIT

## 👨‍💻 Geliştirici

CTF için geliştirildi. Hack The Box, TryHackMe ve benzeri platformlar için idealdir.

---

**Not**: Root olarak çalıştırmayın! Normal kullanıcı yeterlidir.
