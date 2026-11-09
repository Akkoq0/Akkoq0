<div align="center">

# 🎮 MEVA HUD (GhostLink Engine)
### Enterprise-Grade Tactical Esports P2P WebRTC Audio & Command Platform

[![Next.js](https://img.shields.io/badge/Next.js-14.2-black?style=for-the-badge&logo=next.js)](https://nextjs.org/)
[![TypeScript](https://img.shields.io/badge/TypeScript-5.0-blue?style=for-the-badge&logo=typescript)](https://www.typescriptlang.org/)
[![WebRTC](https://img.shields.io/badge/WebRTC-48kHz_Opus-red?style=for-the-badge&logo=webrtc)](https://webrtc.org/)
[![Docker](https://img.shields.io/badge/Docker-Ready-2496ED?style=for-the-badge&logo=docker)](./Dockerfile)
[![Clean Code](https://img.shields.io/badge/Code-Clean_Architecture-emerald?style=for-the-badge)](./docs/CLEAN_CODE_STANDARDS.md)

</div>

---

## 📖 Genel Bakış

**Meva HUD**, rekabetçi e-spor takımları, klanlar ve turnuva oyuncuları için geliştirilmiş; Discord ve TeamSpeak'e kıyasla **sıfır donanım yükü ve sıfır FPS kaybı** sunan, uçtan uca şifreli (E2EE) P2P taktik komuta merkezidir.

### 🌟 Öne Çıkan Özellikler:
* **48kHz Opus Audio DSP:** Donanım filtreleri (High-pass 85Hz, Presence 3.5kHz EQ, VAD Noise Gate, IGL Ducking).
* **60 FPS Pro Stratbook Studio:** CS2 (Mirage, Inferno, Nuke...), Valorant (Bind, Ascent, Haven...), LoL (Sihirdar Vadisi, ARAM), Dota 2 ve PUBG taktik haritaları.
* **Open-Core Freemium Mimarisi:** Temel ses ve taktik tahtası tamamen açık kaynak ve ücretsiz; klanlar için maç sonu akustik koçluk (`ProAnalyticsService`) ve taktik playbook dışa aktarımı (`TacticalPresetManager`).
* **Sıfır Sunucu Maliyeti:** WebRTC Mesh protokolü ile istemciler arası doğrudan ses aktarımı; sunucu darboğazı yaşanmaz.
* **Mobil Ergonomi & Capacitor Android:** Tek elle kullanıma uygun alt gezinme dock'u (`MobileBottomNav`) ve yüzen ses şeridi.

---

## 🛠️ Kurulum & Çalıştırma

```bash
# 1. Bağımlılıkları yükleyin
npm install

# 2. Geliştirme ortamını başlatın
npm run dev

# 3. Üretim derlemesi (Production Build)
npm run build
npm start
```

### Docker ile Çalıştırma:
```bash
docker build -t meva-hud .
docker run -p 3000:3000 meva-hud
```

### Clean Code Doğrulama Testi:
```bash
node scripts/verify-clean-code.mjs
```

---

## 📂 Dizin Yapısı & Temiz Mimari

```
ghostlink/
├── app/                  # Next.js App Router (Layout, Page, Global Error, API Health)
├── components/           # Presentational UI Bileşenleri (Chat, Stratbook, Layout, Modal)
├── hooks/                # Özel Kancalar (useHubArchitect, useRealtimeChat, useWebRTC)
├── src/core/             # Domain Mantığı (Lisanslama, E-spor Analitiği, Playbook)
│   ├── subscription/     # Open-Core Lisans Yöneticisi
│   ├── esports/          # Maç Sonu İletişim & Koçluk Analitiği
│   └── tactical/         # Taktik Playbook JSON Yöneticisi
├── src/services/         # Uygulama Servisleri (Sunucu Mimarı, Koordinat Hesaplayıcı, Clean Utils)
├── lib/                  # Durum Yönetimi (Zustand Store) & Yardımcılar
├── public/               # Manifest, PWA İkonları ve Statik Varlıklar
└── scripts/              # E2E Test & Otomatik Doğrulama Betikleri
```

---

<div align="center">
Meva Tactical Esports Ecosystem · Geliştirici: <strong>@Akkoq0</strong>
</div>
