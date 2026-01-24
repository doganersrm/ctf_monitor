# 🚀 CTF VPN Monitor - Hızlı Başlangıç

## GitHub'a Yükleme

1. **GitHub'da yeni repo oluştur:**
   - Repo adı: `ctf-vpn-monitor`
   - Public olarak oluştur
   - README ekleme (zaten var)

2. **Dosyaları yükle:**

```bash
# Arşivi çıkart
tar -xzf ctf-vpn-monitor-github.tar.gz
cd ctf-vpn-monitor

# Git başlat
git init
git add .
git commit -m "Initial commit: CTF VPN Monitor v1.0"

# GitHub'a push
git remote add origin https://github.com/YOUR_USERNAME/ctf-vpn-monitor.git
git branch -M main
git push -u origin main
```

## Kullanıcılar İçin Kurulum

Reponuz yayına girdikten sonra kullanıcılar şu komutla kurabilir:

```bash
curl -sSL https://raw.githubusercontent.com/YOUR_USERNAME/ctf-vpn-monitor/main/install.sh | bash
```

## Test

```bash
# Kurulum öncesi test
./test.sh

# Kurulum
./install.sh

# Kullanım
source ~/.bashrc
ctfmon start
ctfmon target -u 10.10.11.202
```

## Güncelleme

Kullanıcılar şu komutla güncelleyebilir:

```bash
ctfmon update
```

Bu komut otomatik olarak GitHub'dan son versiyonu çeker.

## Repo Yapısı

```
ctf-vpn-monitor/
├── README.md           # Ana dokümantasyon
├── install.sh          # Tek dosyalı kurulum scripti (her şey dahil)
├── test.sh            # Test scripti
├── LICENSE            # MIT Lisans
└── .gitignore         # Git ignore kuralları
```

## Özellikler

✅ **Tek dosya**: `install.sh` içinde her şey var
✅ **Gömülü kodlar**: Python ve bash kodları installer içinde
✅ **Kolay güncelleme**: `ctfmon update` komutu
✅ **Kolay kaldırma**: `ctfmon uninstall` komutu
✅ **PATH entegrasyonu**: Otomatik .bashrc/.zshrc güncellemesi

## Sürüm Yönetimi

Yeni sürüm çıkarmak için:

1. `install.sh` içindeki `VERSION` değişkenini güncelle
2. Git tag oluştur:

```bash
git tag -a v1.1.0 -m "Version 1.1.0"
git push origin v1.1.0
```

## Promotion

README'de şunları vurgula:
- ⚡ Tek komutla kurulum
- 🎯 CTF için özelleştirilmiş
- 🔄 Otomatik güncelleme
- 🎨 Modern overlay tasarımı
- 💾 Hafif (< 30KB)

## Örnek Kullanım GIF'i

Eğer ekran kaydı eklemek istersen:

1. `asciinema` veya `peek` ile kaydet
2. GIF'e çevir
3. GitHub Issues'ta yükle
4. README'ye ekle:

```markdown
![Demo](https://user-images.githubusercontent.com/xxx/xxx.gif)
```

## Sosyal Medya

Tweet için örnek:

```
🎯 CTF VPN Monitor - Tek komutla kurulum!

✅ VPN IP'ni her zaman gör
✅ Hedef IP'yi hızlıca ayarla
✅ Overlay tasarım
✅ Tek tıkla IP kopyala

curl -sSL URL | bash

#CTF #HackTheBox #TryHackMe #Kali #PenTest
```

## İletişim

Sorunlar için GitHub Issues kullanın.

---

**Başarılar! 🎉**
