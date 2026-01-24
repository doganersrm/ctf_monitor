#!/bin/bash
# CTF VPN Monitor - Test Scripti

echo "🧪 CTF VPN Monitor Test Başlıyor..."
echo ""

# 1. Test: Kurulum dosyası kontrolü
echo "1️⃣  Kurulum dosyası kontrolü..."
if [ -f "install.sh" ]; then
    echo "   ✅ install.sh mevcut"
    if [ -x "install.sh" ]; then
        echo "   ✅ Çalıştırılabilir"
    else
        echo "   ❌ Çalıştırılabilir değil"
        exit 1
    fi
else
    echo "   ❌ install.sh bulunamadı"
    exit 1
fi
echo ""

# 2. Test: README kontrolü
echo "2️⃣  README kontrolü..."
if [ -f "README.md" ]; then
    echo "   ✅ README.md mevcut"
    line_count=$(wc -l < README.md)
    echo "   ℹ️  Satır sayısı: $line_count"
else
    echo "   ❌ README.md bulunamadı"
    exit 1
fi
echo ""

# 3. Test: Python ve GTK kontrolü
echo "3️⃣  Sistem gereksinimleri kontrolü..."

if command -v python3 &> /dev/null; then
    echo "   ✅ Python3: $(python3 --version)"
else
    echo "   ⚠️  Python3 kurulu değil (kurulum sırasında kurulacak)"
fi

if python3 -c "import gi" 2>/dev/null; then
    echo "   ✅ python3-gi kurulu"
else
    echo "   ⚠️  python3-gi kurulu değil (kurulum sırasında kurulacak)"
fi

if command -v xclip &> /dev/null; then
    echo "   ✅ xclip kurulu"
else
    echo "   ⚠️  xclip kurulu değil (kurulum sırasında kurulacak)"
fi

if command -v notify-send &> /dev/null; then
    echo "   ✅ notify-send kurulu"
else
    echo "   ⚠️  notify-send kurulu değil (kurulum sırasında kurulacak)"
fi
echo ""

# 4. Test: install.sh içerik kontrolü
echo "4️⃣  install.sh içerik kontrolü..."
if grep -q "CTFVPNOverlay" install.sh; then
    echo "   ✅ Overlay kodu gömülü"
else
    echo "   ❌ Overlay kodu eksik"
    exit 1
fi

if grep -q "ctfmon" install.sh; then
    echo "   ✅ CLI wrapper kodu gömülü"
else
    echo "   ❌ CLI wrapper kodu eksik"
    exit 1
fi
echo ""

# 5. Test: Grafik ortam kontrolü
echo "5️⃣  Grafik ortam kontrolü..."
if [ -n "$DISPLAY" ]; then
    echo "   ✅ DISPLAY değişkeni ayarlı: $DISPLAY"
    echo "   ℹ️  Grafik arayüz aktif"
else
    echo "   ⚠️  DISPLAY değişkeni yok"
    echo "   ⚠️  SSH üzerinden bağlantılı olabilirsiniz"
    echo "   ⚠️  Overlay grafik ortamda çalışır"
fi
echo ""

# Sonuç
echo "════════════════════════════════════════════"
echo "✅ Testler tamamlandı!"
echo ""
echo "📦 Kurulum için:"
echo "   ./install.sh"
echo ""
echo "veya"
echo ""
echo "   curl -sSL URL/install.sh | bash"
echo "════════════════════════════════════════════"
