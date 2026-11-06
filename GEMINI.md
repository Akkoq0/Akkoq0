# Global & Workspace Rules (Token Tasarruf Modu & APK Derleme Kuralı)

1. **Yüksek Kalite & Maksimum Token Verimliliği Modu (Tüm Modeller ve Tüm Projeler):**
   - **Kaliteden Sıfır Ödün:** Kod kalitesi, mimari sağlamlık, performans, tip güvenliği (TypeScript) ve UI/UX detaylarında her zaman en üst düzey (production-grade) standartları uygula; hiçbir özelliği yarım veya yüzeysel bırakma.
   - **Sıfır Token İsrafı:** Tasarrufu kod kalitesinden değil; gereksiz sohbet uzatmalarından, tekrar eden özetlerden, tüm dosyayı gereksiz okumaktan ve hatalı deneme-yanılma döngülerinden yap.
   - **Tek Seferde Doğru (First-Time-Right):** Değişiklik yapmadan önce bağımlılıkları ve tipleri tam analiz et; hedefli `StartLine`/`EndLine` okumaları ve nokta atışı `edit_file` çağrılarıyla en az adımda en yüksek kaliteli sonucu üret.
   - **Öz ve Net İletişim:** Kullanıcıya yanıt verirken uzun giriş/kapanış cümleleri kurma; doğrudan yapılan işlemi ve sonucu net biçimde aktar.

2. **APK Derleme Kuralı (Yalnızca İstek Üzerine):**
   - Her prompt sonrasında otomatik olarak Android APK derlemesi (`./gradlew assembleDebug`, `npx cap sync`, vb.) **YAPMA**.
   - APK derlemesini yalnızca kullanıcı açıkça **"apk üret"** (veya "apk derle" / "apk çıkar") dediğinde çalıştır.
