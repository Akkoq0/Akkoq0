# 🐎 ÖTÜKEN — Bozkır Strateji & Simülasyon Oyunu (Godot 4.7 Engine)

Bu dizin, **Ötüken** oyununun bağımsız, saf Godot 4.7 motoru kod tabanıdır. WebRTC, HUD, Ghostlink gibi harici web bileşenlerinden tamamen arındırılmıştır.

---

## 📁 Mimari ve Dizin Düzeni

| Dizin / Dosya | Açıklama |
| :--- | :--- |
| `project.godot` | Godot 4.7 proje yapılandırması, Autoload tanımları ve girdi haritası. |
| `scenes/` | Ana oyun sahneleri (`main.tscn`, `main.gd`). |
| `core/` | Oyun kuralları, durum makineleri, olay veriyolu (`EventBus`, `CommandBus`), mantıksal sistemler ve yapay zeka. |
| `ui/` | Godot tabanlı kullanıcı arayüzü: HUD, çekmeceler (Otağ analiz, taktik), menüler (LAN/IP lobi, ayarlar, yeni oyun). |
| `data/` | Veri odaklı oyun kaynakları (`.tres`): madenler, binalar, birimler, mevsimler, araziler. |
| `units/` | Ordu birimleri, hareket bileşenleri (`army_mobility_component.gd`), ikmal hatları. |
| `world/` | Makro strateji haritası ve mikro yerleşim jeneratörleri/renderlayıcıları. |
| `camera/` | Çift katmanlı geçiş kamerası (`dual_layer_camera.gd`). |
| `input/` | Fare, klavye ve dokunmatik girdi kontrolcüleri. |
| `assets/` | Müzik (`assets/audio/music/`), ses efektleri (`assets/audio/sfx/`), yazı tipleri ve dokular. |
| `tests/` | Mimari doğrulama ve headless entegrasyon test paketi (`test_suite.tscn`, `test_suite.gd`). |
| `tools/` | Katman bağımsızlığı ve tip güvenliği doğrulayıcı scriptler. |

---

## 🎯 Başlangıç & Testler

- **Ana Sahne:** `res://scenes/main.tscn`
- **Headless Test Paketi:**
  ```bash
  godot --headless --path . res://tests/test_suite.tscn
  ```
