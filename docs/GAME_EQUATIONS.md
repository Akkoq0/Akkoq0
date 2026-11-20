# Ötüken — Oyun Denklemleri ve Denge Referansı

Bu belge, Ötüken simülasyon motorundaki temel matematiksel denklemleri, determinizm kurallarını ve sınır korumalarını özetler.

## 1. Savaş ve Turan Manevra Denklemi (`CombatCalculator`)
- **Etkin Saldırı Gücü:**
  $$\text{Güç} = \text{Temel Saldırı} \times \text{Zırh/Silah Çarpanı} \times \text{Moral Çarpanı} \times \text{Turan Manevra Bonusu}$$
- **Sınır Korumaları:**
  - `0 HP` cesetlere hasar verilmez (sonsuz Kut/ganimet istismarı engellidir).
  - Tüm bölenler `maxf(divisor, 0.0001)` ile sıfıra bölme (`NaN`/`INF`) korumalıdır.
  - Moral `[0.0, 100.0]`, yorgunluk `[0.0, 100.0]` aralığında kenetlenir (`clampf`).

## 2. Lojistik, İkmal ve Kış (Zud) Yıpranması
- **Mevsimsel Döngü:** İlkbahar → Yaz → Sonbahar → Kış / Zud.
- **Zud Kış Etkisi:** Yüzey akarsuları donar; derin kuyular (`WELL`) ve pınarlar (`OASIS_SPRING`) açık kalır. Tüm su kaynakları kesilirse yedek at oranı `-0.28`, ordu morali `-18.0` düşer.
- **Hızlı Maç Modu:** Mevsim süresi `22 sn` (Uzun Sefer: `45 sn`), başlangıç kaynakları `1.5x`, zafer eşikleri `%40 bölge` veya `70 Kut + 2 mevsim hegemonya` (16. mevsimde süre zaferi).

## 3. Dinamik Kıtlık ve Kara Borsa (`RegionalMarketEngine`)
- Kervan kesintisi ve çatışma bölgesel kıtlık çarpanını en fazla `3.20x` düzeyine çıkarır.
- Satış birim fiyatı her zaman `<= 0.80 * alış referansı` ile sınırlıdır; gidiş-dönüş sonsuz arbitraj matematiksel olarak imkânsızdır.

## 4. Çok Oyunculu Determinizm
- Çekirdek simülasyonda (`core/`, `units/`) global `randf()` / `randi()` kullanımı **sıfırdır**.
- Tüm rastgelelik tohumlu `RandomNumberGenerator` üzerinden akar; her iki tick'te bir `DeterministicStateHasher` (SHA-256) ile eşzamanlılık doğrulanır.

## 5. Zafer ve Yenilgi Koşulları (`MatchVictoryEvaluator`)
| Mod | Fetih Zaferi | Kut & Kurgan Hegemonyası | Süre Zaferi | Yenilgi |
|---|---|---|---|---|
| **Hızlı Maç** | Bölgelerin >= %40'ı veya tüm rakiplerin elenmesi | `Kut >= 70` ve `2` mevsim hegemonya | 16. Mevsim sonunda en yüksek skor | Hanedan yok oluşu (`DYNASTY_EXTINCT`) |
| **Uzun Sefer** | Bölgelerin >= %60'ı veya tüm rakiplerin elenmesi | `Kut >= 85` ve `4` mevsim hegemonya | 48. Mevsim sonunda en yüksek skor | Hanedan yok oluşu (`DYNASTY_EXTINCT`) |
