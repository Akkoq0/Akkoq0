# ÖTÜKEN 3D RTS — OTONOM MARATON İLERLEME DEFTERİ (`MARATHON LEDGER`)

Bu defter **Faz 18–28** arasındaki tüm mimari kararları, matematiksel denklemleri, yakalanan sapmaları, dosya değişikliklerini ve test/commit kapılarını kalıcı olarak kayıt altına alır.

---

## Faz 18 — Kalıcı Dünya Fiziği, Kademeli Töre Barışı ve Anti-Snowball Motoru
- **Commit:** `76963fe` (Parity güncellemesi: `SteppeEntropyCalculator` & Kışlak sığınma desteği)
- **Temel Dosyalar:** `core/grace_period_manager.gd`, `core/steppe_entropy_calculator.gd`, `data/world/persistent_world_rules.gd/.tres`, `core/commands/step_anti_snowball_tick_command.gd`, `units/offline_doctrine_component.gd`, `core/models/offline_doctrine_decision.gd`
- **Matematiksel Formüller:**
  - Kademeli Töre Barışı: `STAGE_1_FULL_TORE_PEACE` (`0..48s`), `STAGE_2_BORDER_SKIRMISH` (`48..72s`), `STAGE_3_TOTAL_STEPPE` (`72s+`); geç katılan `Uç Beyi` için `48s` kişisel barış (saldırı/düşman casusluğunda düşer).
  - Üssel Tüketim: `base * (1.0 + 0.002 * pow(unit_count, 1.25))`
  - Gıda çürümesi, Çelik/Demir bakımı (`jade` ve `meteoric_iron` korunur), `>= 300` birimde atıl `Kut` erimesi.
- **Test Kapısı:** `46 test fonksiyonu / 731 assertion` (`[PASS]`, 0 uyarı).

## Faz 19 — Hibrit Bozkır Fethi ve Mevsimsel Yaylak / Kışlak Kayması
- **Commit:** `e202c4a`
- **Temel Dosyalar:** `core/territory_manager.gd`, `data/conquest/conquest_rules.gd/.tres`, `core/models/region_data.gd`, `core/models/border_node.gd`, `core/models/claim_contestation_fsm.gd`, `core/commands/capture_border_node_command.gd`, `core/commands/open_yurt_claim_command.gd`, `core/commands/respond_to_yurt_claim_command.gd`, `core/commands/resolve_conquest_aftermath_command.gd`
- **Sistem Özeti:** Yaylak/Kışlak mevsimsel verim ve yıpranma tersinmesi; Yeşim tamgasıyla büyüyen Tuğ yarıçapı ve çakışan Tuğ kervan kesintisi (%85 tavan); Elçi ile 18s Yurt İddiası (Meydan / Ülüş Haraç / Elçi Katli `Kan Davası`); %20 Denetim & `Kavruk Bozkır`; Kutsal Kurgan %51+ çoğunlukta Büyük Kağan Adayı & Koalisyon Savaşı.
- **Test Kapısı:** `47 test fonksiyonu / 742 assertion` (`[PASS]`, 0 uyarı).

## Faz 20 — Asimetrik 3 Yollu Çöküş, Kral Yapıcı Sürgün ve Vasallık
- **Commit:** `1652804` (Parity güncellemesi: `can_vassal_observe_overlord` & `get_observed_overlord_status`)
- **Temel Dosyalar:** `core/collapse_recovery_fsm.gd`, `data/governance/collapse_recovery_rules.gd/.tres`, `core/models/collapse_record.gd`, `core/commands/trigger_collapse_command.gd`, `core/commands/select_collapse_path_command.gd`
- **İstismar Frenleri:** 18s iki yönlü `TRUCE_WITHDRAWAL`; Tâbi Beylik sabit `[0.15, 0.25]` haraç tavanı ve `Kut <= 50`; Sürgünde sabit rafineri kapalı + 160 ordu sınırı + mevsimsel Umut/Sadakat çürümesi -> `DYNASTY_EXTINCT`; 4 mevsim bekleme + `0.0` Şöhret ile dış sınırda `FRONTIER_MARCH_LORD` doğuşu.
- **Test Kapısı:** `48 test fonksiyonu / 756 assertion` (`[PASS]`, 0 uyarı).

## Faz 21 — Ulak Gecikmesi, Toz Perdesi Aldatmacası ve Fiziksel Kervan / Usta Ekonomisi
- **Commit:** `ae356eb`
- **Temel Dosyalar:** `core/courier_dispatch_system.gd`, `core/caravan_logistics_manager.gd`, `data/logistics/courier_and_caravan_rules.gd/.tres`, `units/supply_line_component.gd`, `units/turan_tactics_component.gd`, `units/morale_component.gd`
- **Yakalanıp Çözülen Sapma:** Rank 2 yöneticilerin Rank 3 bileşenlere doğrudan erişmesi yerine `EventBus.army_caravan_resupply_delivered` ile saf DAG ayrışması sağlandı.
- **Test Kapısı:** `49 test fonksiyonu / 767 assertion` (`[PASS]`, 0 uyarı).

## Faz 22 — Yönetişim Sınırı, Ülüş Sabotajı, Amanat, İtibar Hafızası ve 48 Mevsim Denetimi
- **Commit:** `f23eceb`
- **Temel Dosyalar:** `core/governance_manager.gd`, `core/reputation_and_pact_system.gd`, `data/governance/politics_and_pacts_rules.gd/.tres`, `core/models/vassal_bey_assignment.gd`, `core/models/amanat_pact_record.gd`, `core/models/proxy_war_contract.gd`, `core/diplomacy_manager.gd`, `tests/long_horizon_simulator.gd`, `tests/simulation_invariant_checker.gd`
- **Yakalanıp Çözülen Sapma:**
  1. `DiplomacyManager.evaluate_all_dynasties` içinde yüksek `Dehşet` / kötü şöhret kaynaklı koalisyonun `Kut >= 30` iken her mevsim kapanıp açılması (`43x` sinyal fırtınası) `joins_by_infamy` kontrolü ile çözüldü.
  2. 48 mevsimlik 5 arketip stres koşumunda çift otlatma ve zanaatkâr kervan rotasyonu kalibre edilerek `0` invariant ihlali doğrulandı.
- **Test Kapısı:** `50 test fonksiyonu / 781 assertion` (`[PASS]`, 0 uyarı).

## Faz 23 — Bozkır Su Hatları, Kuyu Sabotajı ve Dinamik Kıtlık / Kara Borsa Ekonomisi
- **Temel Dosyalar:** `core/water_route_manager.gd`, `core/regional_market_engine.gd`, `data/economy/water_and_market_rules.gd/.tres`, `core/models/water_source_node.gd`, `core/models/regional_market_state.gd`, `core/commands/sabotage_well_command.gd`, `core/commands/restore_water_source_command.gd`, `core/commands/execute_barter_trade_command.gd`, `units/supply_line_component.gd`, `units/morale_component.gd`
- **Matematik ve Mekanikler:**
  - Kış/Zud döneminde yüzey akarsuları (`STEPPE_STREAM`) donarken derin yeraltı kuyuları (`WELL`) ve `OASIS_SPRING` pınarları açık kalır; tüm su kaynakları tükendiğinde `EventBus.water_crisis_inflicted` aracılığıyla `remount_horse_ratio` (`-0.28`) ve `morale` (`-18.0`) cezaları Rank 3 bileşenlere saf DAG üzerinden uygulanır.
  - `SabotageWellCommand` düşman kuyusuna karşı `GracePeriodManager.validate_and_commit_action(..., BORDER_NODE_RAID)` kapısından geçer (Töre Barışı / Çöküş Mütarekesi istismarı engellendi); `SCORCHED_EARTH_PILLAGE` (`Kavruk Bozkır`) bölge kuyularını otomatik zehirler.
  - `RegionalMarketEngine` kesilen kervan (`caravan_intercepted_crisis`) ve çatışmalı ocak düğümlerinde (`border_node_captured`) bölgesel kıtlığı artırır (`<= 3.20x`). `HOMELESS_EXILE` açık lonca ticaretinden men edilir, yalnızca `is_black_market` ile takas yapabilir. Satış birim fiyatı `<= 0.80 * ask_ref` + navlun kesintisiyle gidiş-dönüş arbitrajı matematiksel olarak imkânsızdır.
- **Yakalanıp Çözülen Sapma:**
  1. `WaterRouteManager._sources_by_region` untyped `Array` nedeniyle oluşan Godot 4.7 Seviye-2 `unsafe_cast` hatası `Dictionary[Vector2i, PackedStringArray]` ile çözüldü.
  2. `MoraleComponent._ready()` / `_exit_tree()` içine `EventBus.water_crisis_inflicted` bağlantısı eklendi ve `_test_phase23_water_routes_and_scarcity_market()` + Faz 18/20 parity doğrulamaları `_run_suite()` içine bağlandı.
- **Test Kapısı:** `51 test fonksiyonu / 801 assertion` (`[PASS]`, 0 uyarı).

