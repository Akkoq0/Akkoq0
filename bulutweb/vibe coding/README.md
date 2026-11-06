# TimeNest

Saat mağazası, Node.js/Express backend ve SQLite veritabanı ile çalışır.
Hosting ortamında Node.js `20.17.0` veya üzeri kullanın.

## Yerel çalıştırma

```bash
cd "/workspaces/Akkoq0/bulutweb/vibe coding"
npm install
npm start
```

`.env` dosyası hazırdır. Admin kullanıcı adı/parolasını ve `SESSION_SECRET` değerini doldur; parola en az 16 karakter, kullanıcı adından farklı ve yalnızca bu site için kullanılan bir parola olmalı. `SESSION_SECRET` en az 32 karakterli ve rastgele olmalı. Sunucuyu yeniden başlatınca admin hesabı bu bilgilerle güncellenir. Mağaza `http://localhost:3000`, admin girişi `http://localhost:3000/login` adresindedir.

Testleri çalıştırmak için `npm test` komutunu kullanın.
Tarayıcı senaryosu `npm run test:browser` ile çalıştırılır; bunun için Playwright Chromium işletim sistemi kütüphaneleri gereklidir.
Satışa hazır olup olmadığını denetlemek için `npm run launch:check` komutunu çalıştırın. Eksik her alanı açıkça listeler. Yerelde değerleri `.env` dosyasında; hosting üzerinde ise sağlayıcının gizli ortam değişkenleri bölümünde tanımlayın. Hosting ortam değişkenleri kullanıldığında `.env` dosyası gerekmez.

## Shopier bağlantısı ekleme

1. Shopier hesabında ürünü oluşturup ödeme bağlantısını alın.
2. `/login` üzerinden admin paneline girin; yeni ürün ekleyin veya mevcut ürünü düzenleyin.
3. Shopier bağlantısını ilgili alana yapıştırın ve Shopier'deki fiyat ile mağaza fiyatının aynı olduğunu kontrol edin.

Bağlantı girilen ürünlerde mağaza müşteriyi Shopier'e yönlendirir. Ödeme kart bilgilerini Shopier işler. Shopier ile site siparişleri arasında otomatik ödeme bildirimi bu projede yoktur. Admin'e düşen bir siparişte tahsilatı Shopier panelinden doğrulamadan “İşleniyor” seçmeyin.

Shopier tahsilatını elle kaydetmek için admin panelinde “Shopier ödemeli sipariş kaydet” formunu kullanın. Ödeme Shopier panelinde başarılı görünmeden formu göndermeyin; sipariş no/referans bilgisini kayda ekleyin. Bu işlem stoğu ayırır ve SMTP ayarlıysa müşteriye onay e-postası yollar.

## Stok ve kargo

Admin ürün formunda gerçek eldeki stok miktarını girin. Stok sıfırken mağazada satın alma kapalıdır. Shopier tahsilatını doğruladıktan sonra admin siparişini “İşleniyor” yaptığında stok ayrılır; iptal durumuna alınırsa stok geri eklenir. Kargoya verildiğinde firma ve takip numarasını girin. SMTP kurulmuşsa durum ve takip bilgisi müşteriye e-postalanır.

## E-posta

Hazır `.env` içindeki `SMTP_HOST`, `SMTP_PORT`, `SMTP_SECURE`, `SMTP_USER`, `SMTP_PASSWORD` ve `MAIL_FROM` alanlarını SMTP sağlayıcınızın gerçek bilgileriyle doldurun. Gerçek değerleri Git'e eklemeyin; `.env` ignore edilir. SMTP bilgisi yoksa sipariş ve kargo e-postaları gönderilmez ama kayıt akışı çalışmaya devam eder.

## Yasal metinler ve yayına hazırlık

`legal.html` gizlilik/KVKK, ön bilgilendirme, mesafeli satış, cayma-iade ve kargo başlıkları için taslaktır; köşeli parantezli işletme bilgilerini doldurun ve hukuk uzmanına inceletin. İnceleme tamamlanmadan `.env` içindeki `LEGAL_REVIEWED` değerini `true` yapmayın. Eksik alanlarla gerçek satışa başlamayın. Gerçek Shopier ödeme bildirimi, stok senkronizasyonu ve iade/iptal sonrası tahsilat işlemleri için Shopier hesabına özel resmi API/webhook erişimi gerekir; bunlar olmadan otomatik ödeme doğrulaması yapılmaz.

## Production güvenliği

Production için `.env` dosyasındaki değişkenleri gerçek değerlerle doldurun:

- `NODE_ENV=production`
- `SITE_URL`: gerçek HTTPS alan adınız
- `SESSION_SECRET`: uzun, rastgele ve gizli bir değer
- `ADMIN_USERNAME`: yönetici kullanıcı adı
- `ADMIN_PASSWORD`: en az 16 karakterli, örnek olmayan ve yalnızca bu site için kullanılan parola
- `SHOPIER_PAYMENT_MODE=manual-links`

Örnek `.env` değerleriyle production sunucusu başlamaz; `npm start` güvenli olmayan örnek ayarları reddeder. Değerleri kaynak koda veya Git deposuna eklemeyin. Hosting ortam değişkenleri/gizli ayarlar bölümünü kullanın. Yerel `.env` dosyasının izinleri `0600` olmalıdır. HTTPS kullanın; production oturum çerezi `Secure` olarak ayarlanır. Başlangıçta tanımlanan yönetici bilgileri veritabanındaki yönetici hesabını günceller.

Canlıda deneme siparişi endpoint'i kapalıdır; sepet sayfasındaki deneme formu da gösterilmez. Gerçek ödeme bağlantısı bulunan ürünler Shopier'e yönlendirilir. Sipariş ve tahsilat eşleştirmesi mevcut sürümde manuel yapılır.

Sunucu, nonce kullanan Content Security Policy ve tarayıcı güvenlik başlıkları gönderir; admin/giriş sayfaları önbelleğe alınmaz. Ürün görselleri yalnızca HTTPS üzerinden kabul edilir. Ürün kataloğu yüklenemezse eski örnek ürünleri satışta göstermez. Görseller gecikmeli yüklenir; sepet ve admin sayfaları küçük ekranlarda da test edilir. Yayın öncesi backend ve mobil tarayıcı testlerini, ayrıca `npm audit --omit=dev` kontrolünü çalıştırın.

SQLite veritabanı `data/timenest.db` içinde tutulur; bu klasör web üzerinden servis edilmez ve Git'e eklenmemelidir.