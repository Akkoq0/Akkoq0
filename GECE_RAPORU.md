# GECE RAPORU — ÖTÜKEN MOBİL RTS DÖNÜŞÜMÜ

## 1. Faz Özeti

### Faz 0 — Klasör Doğrulama, Anayasa & APK Hattı
- `Otuken_Godot` proje kökü (`/home/antigravity/projects/Otuken_Godot`) `ghostlink` (`Meva_Ghostlink`) ve `bulutweb` (`Legacy_Bulutweb`) dizinlerinden tamamen arındırılarak saf Godot 4.7.2-stable projesine dönüştürüldü.
- Kök dizine `PROJE_ANAYASASI.md` eklendi; `export_presets.cfg` içine `reports/*` hariç tutma kuralı işlendi.
- `.github/workflows/build-otuken-apk.yml` doğrulandı (`--path .` kök `project.godot` ve `res://tests/test_suite.tscn` kapısıyla hizalı).

### Faz 1 — Ana Menü, Gerçek Godot Wi-Fi (LAN), Grafik Ayarları & Mobil HUD
- **Açılış Ana Menüsü (`res://scenes/main_menu.tscn` -> `project.godot run/main_scene`):**
  - Arka planda dönen canlı 3D bozkır vadisi ve altın saat atmosferi üzerinde `"ÖTÜKEN"` ana menüsü kuruldu.
  - **Tek Oyunculu (Sefer)**, **Aynı Wi-Fi / LAN Oyna**, **Grafik Ayarları** ve **Çıkış** seçenekleri çalışır durumda.
- **Gerçek Godot `ENetMultiplayerPeer` LAN Lobisi (Port 7777):**
  - **Oda Kur (Host):** ENet sunucusu başlatır ve `IP.get_local_addresses()` üzerinden yerel IP adresini (`192.168.x.x` / `10.x.x.x`) ekranda büyük gösterir; `"Maçı Başlat"` ile Host ve Client aynı maça girer.
  - **Odaya Katıl (Join):** IP kutusu ve `"Bağlan"` butonu ile bağlanır; oyun içi inşa, asker basma, hareket ve saldırı komutları `@rpc("any_peer", "call_local", "reliable")` üzerinden senkronize edilir.
- **Mobil Grafik Ayarları (`core/graphics_quality_applier.gd` & `ui/menus/graphics_settings_modal.gd`):**
  - `user://graphics_settings.cfg` dosyasına kalıcı kayıt yapar; sahneyi yeniden başlatmadan anlık uygulanır.
  - 4 hazır profil (*Düşük*, *Orta*, *Yüksek*, *Gerçekçi*) + Çözünürlük Ölçeği (`%60/%75/%90/%100`), Gölge Kalitesi (`Kapalı/Düşük/Orta/Yüksek`), Bitki & Ağaç Yoğunluğu (`%25/%50/%80/%100`), Atmosferik Sis (`Açık/Kapalı`), FPS Limiti (`30/60`) ve Canlı FPS Sayacı (`Açık/Kapalı`).
- **Temiz Mobil HUD (`ui/hud/mobile_rts_hud.gd`):**
  - Üstte tek satır kaynak barı (`Erzak`, `Gümüş`, `Çelik`, `Taş`, `Ordu` + anlık `+gelir`), sağ üstte dokunarak kamera atlatan canlı etkileşimli **Minimap**, üst sağda `Ayarlar / Detay / Menü` düğmeleri, altta en az `56px` yüksekliğinde bağlamsal **İnşa & Komuta Çubuğu**.
  - Karmaşık analiz çekmecesi açılışta kapalıdır (`"Detay"` ile açılır).

### Faz 2 — Tam Oynanış Döngüsü, Gerçek Savaş & Aktif Yapay Zeka
- **`scenes/rts_battlefield_manager.gd`:**
  - Güneybatıda Oyuncu Baş Otağı + başlangıç Atlı Okçu bölüğü; Kuzeydoğuda Düşman AI Baş Otağı + Demirci Ocağı + başlangıç bölüğü ile maç başlar.
  - Dokunmatik/fare ile yeşil-kırmızı önizlemeli bina dikimi (`Otağ`, `Demirci Ocağı`, `Taş Ocağı`, `Kurgan`), canlı kaynak döngüsü, otağ/ocaktan birlik eğitimi (`Atlı Okçu`, `Ağır Süvari`, `İkmal Öküzü`), birim seçme, yürüme halkası, yol çizgisi ve düşmanı kovalayıp saldırma tam çalışır.
  - Her vuruş `CombatCalculator` üzerinden hesaplanır; 3D dünya üstü Can Barları düşer, havaya yükselen `"-24"` hasar yazıları, kavisli ok izi, yakın dövüş kıvılcımı ve yürüme tozu üretilir.
  - Baş Otağ yıkıldığında **ZAFER / YENİLGİ** istatistik ekranı açılır.

### Faz 3 — Manor Lords PBR Arazi, Doğa, 3D Modeller & Tak-Çıkar Yuvalar
- Eski 8x8 ayrık kareler, renkli küreler ve yeşil küp canlı oyundan tamamen kaldırıldı (`_hide_legacy_debug_visuals()`).
- **`world/common/steppe_pbr_terrain.gd`:**
  - Tek parça `SurfaceTool` heightmap (`get_height_at(x, z)`), orta vadide kıvrılan nehir ve geçitler, kenarlarda uzak bozkır dağ silueti, eğime/yüksekliğe/neme göre `Grass001`, `Ground037`, `Snow006` + önbellekli `FastNoiseLite` NormalMap/Roughness harmanlı PBR shader ve dalgalı su yüzeyi eklendi.
  - **Mobil Güvenlik Kilidi:** `SSR`, `SDFGI` ve `Volumetric Fog` kesinlikle kapalıdır (`ACES` tonemapping + `ProceduralSkyMaterial`).
  - `MultiMeshInstance3D` ile çam ormanları (`380`), kayalıklar (`120`) ve rüzgârda salınan ot kümeleri (`640`) eklendi; bitki yoğunluğu grafik ayarına bağlıdır.
- **`world/common/rts_visual_factory.gd` & `assets/models/`:**
  - Tüm yapılar, bölükler (5 figürlü süvari/okçu formasyonu, öküz arabası) ve maden kaya damarları çok parçalı PBR modeller olarak üretildi.
  - `res://assets/models/` altına `otag.glb`, `kisla_ocak.glb`, `tas_ocagi.glb`, `kurgan.glb`, `atli_okcu.glb`, `agir_suvari.glb`, `ikmal_okuzu.glb`, `cam_agaci.glb` bırakıldığında otomatik yükleme yuvaları hazırlandı (dış CC0 Poly Haven tekil `.glb` sunmadığı ilk denemede görülerek B planı prosedürel PBR + mevcut CC0 dokularla devam edildi).
- `AudioDirector` ve `res://assets/audio/` altındaki tüm müzik ve SFX dosyaları eksiksiz korundu ve bağlandı.
- `xvfb-run` + Mesa OpenGL3 ile `1280x720` canlı sahne görüntüsü alındı: `reports/night_preview.png`.

---

## 2. Doğrulama & Davranış Ölçüm Sonuçları

- **`res://tests/night_behavior_audit.tscn`:** **13/13 assertion PASS (0 hata)**
  - **AI İlk Bina İnşası:** `10.5 sn`
  - **AI İlk Birlik Eğitimi:** `10.5 sn`
  - **İlk Gerçek Çatışma Teması:** `12.0 sn`
  - **120 sn Simülasyon Çatışma İstatistiği:** `86 vuruş`, toplam `1763.0` gerçek HP hasarı
  - **Geometri Zemin Denetimi:** Tüm bina ve birimler `get_height_at(x, z)` ile tam hizalı (`0` uçan/gömülü hata)
  - **HUD Çakışma Denetimi (`1920x1080` & `1600x720`):** `0` buton çakışması (`Rect2.intersects`)
- **`res://tests/test_suite.tscn`:** **971/971 assertion PASS (0 hata, 0 ArchitectureVerifier DAG/Level-2 typing ihlali)**
- **Hedef Mobil FPS:** Varsayılan Android Dengeli profil `60 FPS` (`%75` 3D ölçek, düşük gölge, %50 bitki); Pil/Düşük profil `30 FPS` (`%60` ölçek, gölge kapalı).

---

## 3. Sabah APK Açıldığında Kullanıcı Ne Görecek?
1. Açılışta dönen canlı 3D altın-saat bozkırı üzerinde **ÖTÜKEN** Ana Menüsü (`Tek Oyunculu`, `Aynı Wi-Fi / LAN Oyna`, `Grafik Ayarları`, `Çıkış`).
2. **Aynı Wi-Fi / LAN Oyna** seçildiğinde gerçek `ENet` Port `7777` lobisi; Kurucu ekranda kendi yerel IP'sini büyük görür, arkadaşı IP yazıp bağlanır.
3. Maça girildiğinde tek parça engebeli yeşil-altın bozkır vadisi, ortada dalgalanan nehir, uzak dağlar, çam ormanları, güneybatıda kendi Baş Otağı ve 5 kişilik süvari bölüğü; üstte tek satır kaynak barı, sağ üstte tıklanabilir Minimap, altta başparmak boyutunda bağlamsal inşa/asker/saldırı çubuğu.
4. Bina dikip asker bastıkça kuzeydoğudaki AI rakip ~10 saniye içinde kendi binalarını dikip asker basarak baskına gelir ve 3D can barları ile ok/kılıç çatışması başlar.
