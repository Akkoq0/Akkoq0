# PROJE ANAYASASI — ÖTÜKEN (GODOT 4.7.2-STABLE)

Bu belge, Ötüken projesinin mimari, performans, dosya ve kalite kurallarını kesin olarak tanımlar.

## 1. Motor ve Tip Güvenliği Disiplini
- **Motor Sürümü:** `Godot 4.7.2-stable` (Mobile Renderer).
- **Strict Static Typing (Level-2):**
  - Tüm `.gd` dosyalarında `:=` (inferred declaration) **YASAKTIR**. Her değişken açık tip tanımı (`var ad: Tip = ...`) kullanır.
  - Her `const`, `var`, fonksiyon parametresi ve fonksiyon dönüş tipi (`-> ReturnType`) açıkça belirtilir.
  - `project.godot` üzerindeki Level-2 uyarıları (`untyped_declaration`, `inferred_declaration`, `unsafe_property_access`, `unsafe_method_access`, `unsafe_cast`, `unsafe_call_argument`) sıfır ihlal ile korunur.
- **Katmanlı DAG Mimarisi (`tools/verify_architecture.gd`):**
  - Rank 0 (`core/types/`) -> Rank 1 (`data/`) -> Rank 2 (`core/`) -> Rank 3 (`world/`, `units/`, `camera/`, `buildings/`, `input/`) -> Rank 4 (`scenes/`, `ui/`, `tools/`, `tests/`).
  - Alt katman üst katmana doğrudan bağımlı olamaz; döngüsel bağımlılık yasaktır.

## 2. Mobil Yüksek FPS & Görsel Kalite Kilidi
- **Yasaklı Ağır Efektler:** Mobil GPU uyumluluğu için `SSR`, `SDFGI` ve `Volumetric Fog` **KESİNLİKLE YASAKTIR**.
- **PBR & ACES Standartı:** Doğal renk paleti (cırtlak çizgi film renkleri yasak), eğime/yüksekliğe duyarlı arazi materyalleri, önbelleğe alınmış prosedürel dokular, `MultiMeshInstance3D` tabanlı doğa instancing ve grafik kalitesi ayarlarıyla (`user://graphics_settings.cfg`) dinamik ölçekleme zorunludur.
- **Sıfır Çakışma UI:** Tüm ekranlarda (1920x1080 ve 1600x720) dokunmatik dostu (en az 56px alt aksiyon çubuğu), taşmayan ve birbirine çarpmayan HUD düzeni korunur.

## 3. Ses ve Mevcut Varlık Koruması
- `res://assets/audio/music/` ve `res://assets/audio/sfx/` altındaki mevcut müzik ve ses efektleri **ASLA silinmez**.
- Tüm sesler `AudioDirector` Autoload üzerinden yönetilir.

## 4. Proje Ayrımı & Test Kapısı
- `Otuken_Godot` tamamen bağımsız saf Godot projesidir; `Meva_Ghostlink` ve `Legacy_Bulutweb` klasörlerine dokunulmaz.
- Her faz sonunda `res://tests/test_suite.tscn` ve faz doğrulamaları çalıştırılıp 0 hata ile geçtikten sonra temiz git checkpoint commit atılır.
