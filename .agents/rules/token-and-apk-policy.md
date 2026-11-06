---
trigger: always_on
---

# Maksimum Kalite / Minimum Token Modu & APK Derleme Kuralı

- **Yüksek Kalite & Token Verimliliği (Her Zaman Aktif):** Tüm modellerde ve projelerde kod, mimari ve UI/UX kalitesinden **asla ödün verme** (her zaman production-grade, eksiksiz ve hatasız kod üret). Token tasarrufunu koddan kısarak değil; gereksiz sohbet metinlerini, tekrarları, gereksiz tam dosya okumalarını (`StartLine`/`EndLine` kullan) ve deneme-yanılma turlarını sıfırlayarak sağla.
- **APK Derleme Kuralı:** Kullanıcı açıkça **"apk üret"** demediği sürece otomatik APK derlemesi (`gradlew`, `cap sync` vb.) başlatma.
