# CTF VPN Monitor 🔒

**Kali Linux için VPN ve hedef IP izleme aracı - CTF çözenlerin yeni en iyi arkadaşı!**

![Version](https://img.shields.io/badge/version-2.0-blue.svg)
![Platform](https://img.shields.io/badge/platform-Kali%20Linux-557C94.svg)
![Python](https://img.shields.io/badge/python-3.7+-green.svg)
![License](https://img.shields.io/badge/license-MIT-orange.svg)

<p align="center">
  <img src="https://img.shields.io/badge/HackTheBox-Compatible-9FEF00.svg" alt="HTB">
  <img src="https://img.shields.io/badge/TryHackMe-Compatible-C11111.svg" alt="THM">
</p>

---

## 📸 Önizleme

```
● VPN: 10.10.14.15 │ ■ Local: 192.168.1.108 │ ▸ Target: 10.10.11.202
```

**Ekranın üst ortasında her zaman görünür - Hiçbir pencereyi kaplamaz!**

<img width="2559" height="732" alt="image" src="https://github.com/user-attachments/assets/f5cbb164-8fcb-47fb-be1d-695aa8f71f16" />


---

## ✨ Özellikler

- 🟢 **VPN IP Takibi** - tun0 arayüzünden otomatik algılama
- 💻 **Local IP Gösterimi** - Ağ arayüzünüzü otomatik bulur
- 🎯 **Target IP Yönetimi** - CTF hedef makinenizi kaydedin
- 🔄 **Otomatik Güncelleme** - Her 5 saniyede bir yenilenir
- 🎨 **Renkli Gösterim** - Durumları hemen anlayın (bağlı/bağlı değil)
- 📋 **Tek Tıkla Kopyalama** - IP'leri panoya hızlıca kopyalayın
- 👻 **Tamamen Şeffaf** - Sadece yazılar görünür, arka plan yok
- 🖱️ **Sağ Tık Menüsü** - Tüm özelliklere kolay erişim
- ⚡ **Hafif** - ~25MB RAM kullanımı
- 🚀 **Hızlı Başlangıç** - 30 saniyede kurulum

---

## 🚀 Hızlı Başlangıç

### Kurulum

```bash
# Repository'yi klonla
git clone https://github.com/doganersrm/ctf_overlay.git
cd ctf_overlay

# Gerekli paketleri kur
./ctf_vpn_cli.sh install

# Overlay'i başlat
./ctf_vpn_cli.sh overlay
```

### Temel Kullanım

```bash
# Hedef IP ayarla
./ctf_vpn_cli.sh target -u 10.10.11.202

# Durum kontrol
./ctf_vpn_cli.sh status

# Yeniden başlat
./ctf_vpn_cli.sh restart

# Durdur
./ctf_vpn_cli.sh stop
```

---

## 💻 Gereksinimler

- **İşletim Sistemi:** Kali Linux 2020.1+
- **Python:** 3.7+
- **Desktop Environment:** XFCE, GNOME, KDE, MATE
- **Paketler:** 
  - `python3`
  - `python3-gi`
  - `xclip` (opsiyonel - IP kopyalama için)
  - `libnotify-bin` (opsiyonel - bildirimler için)

---

## 📖 Kullanım Kılavuzu

### Komutlar

| Komut | Açıklama |
|-------|----------|
| `overlay` | Overlay'i başlat |
| `target -u <IP>` | Hedef IP ayarla |
| `target --clear` | Hedef IP temizle |
| `status` | Mevcut durumu göster |
| `stop` | Overlay'i durdur |
| `restart` | Overlay'i yeniden başlat |
| `install` | Gerekli paketleri kur |

### Overlay Özellikleri

- ✅ Ekranın üst ortasında her zaman görünür
- ✅ Tamamen şeffaf arka plan
- ✅ Hiçbir pencereyi kaplamaz
- ✅ Conky benzeri davranış
- ✅ Büyük ve kalın yazı tipi
- ✅ Güçlü gölge efekti (her arka planda okunabilir)

---

## 🎮 CTF Workflow Örnekleri

### HackTheBox

```bash
# 1. VPN'e bağlan
sudo openvpn lab_username.ovpn

# 2. Overlay'i başlat (ilk seferde)
./ctf_vpn_cli.sh overlay

# 3. Makine IP'sini ayarla
./ctf_vpn_cli.sh target -u 10.10.11.202

# 4. Hack away! 🎯
```

### TryHackMe

```bash
# 1. VPN'e bağlan
sudo openvpn username.ovpn

# 2. Room'un target IP'sini ayarla
./ctf_vpn_cli.sh target -u 10.10.123.45

# 3. Start hacking!
```

---

## 🎨 Renkler ve Semboller

| Sembol | Anlam | Renk |
|--------|-------|------|
| ● | VPN durumu | 🟢 Bağlı / 🔴 Bağlı değil |
| ■ | Local IP | 🔵 Mavi |
| ▸ | Target IP | 🟠 Turuncu |

---

## ⚙️ İleri Seviye

### Alias Oluşturma

`.bashrc` veya `.zshrc` dosyanıza ekleyin:

```bash
# CTF VPN Monitor
alias vpn='~/ctf-vpn-monitor/ctf_vpn_cli.sh'
alias target='~/ctf-vpn-monitor/ctf_vpn_cli.sh target -u'
```

Kullanım:
```bash
vpn overlay           # Başlat
target 10.10.11.202   # Hedef ayarla
vpn status            # Durum
```

### Otomatik Başlatma

```bash
mkdir -p ~/.config/autostart

cat > ~/.config/autostart/ctf-vpn-overlay.desktop << 'EOF'
[Desktop Entry]
Type=Application
Name=CTF VPN Overlay
Exec=/bin/bash -c 'sleep 5 && python3 /tam/yol/ctf-vpn-monitor/ctf_vpn_overlay.py'
Icon=network-vpn
Terminal=false
Categories=Network;
EOF
```

### Farklı VPN Arayüzü

`tun0` yerine farklı arayüz kullanıyorsanız (`tun1`, `tap0`, vb.):

```python
# ctf_vpn_overlay.py dosyasını düzenle
nano ctf_vpn_overlay.py

# Satır ~260 civarı:
result = subprocess.run(
    ['ip', 'addr', 'show', 'tun1'],  # tun0 → tun1
    ...
)
```

---

## 🐛 Sorun Giderme

### Overlay görünmüyor

```bash
# Log dosyasını kontrol et
cat /tmp/ctf_vpn_monitor.log

# Manuel başlat
python3 ctf_vpn_overlay.py

# Paketleri yeniden kur
./ctf_vpn_cli.sh install
```

### VPN IP gösterilmiyor

```bash
# VPN arayüzünü kontrol et
ip addr show | grep tun

# Arayüz farklıysa scripti düzenle
```

### Kopyalama çalışmıyor

```bash
# xclip'i kur
sudo apt-get install xclip
```

---

## 📁 Proje Yapısı

```
ctf-vpn-monitor/
├── ctf_vpn_overlay.py      # Ana overlay programı
├── ctf_vpn_cli.sh           # CLI arayüzü
├── README.md                # Bu dosya
├── LICENSE                  # MIT Lisansı
└── .gitignore               # Git ignore
```

---

## 🤝 Katkıda Bulunma

Katkılarınızı bekliyoruz! 

1. Fork edin
2. Feature branch oluşturun (`git checkout -b feature/AmazingFeature`)
3. Commit edin (`git commit -m 'Add some AmazingFeature'`)
4. Push edin (`git push origin feature/AmazingFeature`)
5. Pull Request açın

### Önerilen Özellikler

- [ ] Otomatik port tarama
- [ ] Reverse shell generator
- [ ] Quick terminal commands
- [ ] Timer/süre takibi
- [ ] Multi-target support
- [ ] HTB/THM API entegrasyonu

---

## 📝 Değişiklik Geçmişi

### v2.0 - Overlay Edition (2025-01-22)
- ✨ Overlay modu (tamamen şeffaf, her zaman üstte)
- 🎨 Renkli IP gösterimi
- 📋 Tek tıkla IP kopyalama
- 🖱️ İyileştirilmiş menü sistemi
- ⚡ Büyük ve kalın yazı tipi
- 🔧 Pozisyon ayarlama özellikleri

---

## 📄 Lisans

Bu proje MIT lisansı altında lisanslanmıştır. Detaylar için [LICENSE](LICENSE) dosyasına bakın.

---

## 👨‍💻 Geliştirici

**CTF VPN Monitor** - CTF tutkunları için geliştirilmiştir.

- Sorular için: [Issues](https://github.com/KULLANICI_ADINIZ/ctf-vpn-monitor/issues)
- Özellik önerileri: [Discussions](https://github.com/KULLANICI_ADINIZ/ctf-vpn-monitor/discussions)

---

## 🙏 Teşekkürler

- Tüm CTF community'sine
- HackTheBox ve TryHackMe platformlarına
- Kali Linux ekibine

---

## ⭐ Star History

Eğer bu proje işinize yaradıysa, lütfen bir ⭐ verin!

---

<p align="center">
  <b>Happy Hacking! 🎯🔒</b>
  <br>
  <i>"Know your IPs, dominate the CTFs!"</i>
</p>

---

**Not:** Bu araç sadece yasal ve etik penetrasyon testleri için tasarlanmıştır. Kullanıcılar, aracı kullanırken tüm yerel yasalara ve düzenlemelere uymakla yükümlüdür.
