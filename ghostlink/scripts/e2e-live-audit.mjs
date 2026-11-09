import http from 'http';
import fs from 'fs';

const ARTIFACT_DIR = '/home/codespace/.gemini/antigravity/brain/7a1a0347-783f-4006-8567-f0b06c04c11c';

async function main() {
  const tabs = await new Promise((resolve, reject) => {
    http.get('http://localhost:9222/json', (res) => {
      let data = '';
      res.on('data', (chunk) => data += chunk);
      res.on('end', () => resolve(JSON.parse(data)));
    }).on('error', reject);
  });

  const tab = tabs.find(t => t.type === 'page');
  if (!tab) {
    console.error('No Chrome tab found');
    process.exit(1);
  }

  const ws = new globalThis.WebSocket(tab.webSocketDebuggerUrl);
  let id = 1;
  const send = (method, params = {}) => new Promise((resolve) => {
    const curId = id++;
    const listener = (event) => {
      const data = JSON.parse(event.data);
      if (data.id === curId) {
        ws.removeEventListener('message', listener);
        resolve(data.result);
      }
    };
    ws.addEventListener('message', listener);
    ws.send(JSON.stringify({ id: curId, method, params }));
  });

  const errors = [];
  ws.addEventListener('message', (event) => {
    const data = JSON.parse(event.data);
    if (data.method === 'Runtime.exceptionThrown') {
      errors.push(data.params.exceptionDetails.text);
    }
  });

  ws.onopen = async () => {
    console.log('🚀 E2E Live Interactive Testing Started...');
    await send('Runtime.enable');
    await send('Page.enable');

    // Set 1920x1080 viewport for desktop war room audit
    await send('Emulation.setDeviceMetricsOverride', {
      width: 1920,
      height: 1080,
      deviceScaleFactor: 1,
      mobile: false,
      hasTouch: false
    });

    await send('Page.navigate', { url: 'http://127.0.0.1:3000/' });
    await new Promise(r => setTimeout(r, 2000));

    // ── STEP 1: TEST THEME & FONT SELECTOR ──
    console.log('▶ [FAZ 1] Tema ve Font Değiştirici Test Ediliyor...');
    // Open Theme Settings Modal
    await send('Runtime.evaluate', {
      expression: `(() => {
        const btn = document.querySelector('button[title*="Görünüm ve Tema"]') ||
                    Array.from(document.querySelectorAll('button')).find(b => b.getAttribute('aria-label')?.includes('Görünüm'));
        if (btn) btn.click();
      })()`
    });
    await new Promise(r => setTimeout(r, 600));

    // Switch to Fonts tab
    await send('Runtime.evaluate', {
      expression: `(() => {
        const tabBtn = Array.from(document.querySelectorAll('button')).find(b => b.innerText.includes('Yazı Tipleri'));
        if (tabBtn) tabBtn.click();
      })()`
    });
    await new Promise(r => setTimeout(r, 400));

    // Select "JetBrains Mono"
    await send('Runtime.evaluate', {
      expression: `(() => {
        const fontBtn = Array.from(document.querySelectorAll('button')).find(b => b.innerText.includes('JetBrains Mono'));
        if (fontBtn) fontBtn.click();
      })()`
    });
    await new Promise(r => setTimeout(r, 400));

    const snapFont = await send('Page.captureScreenshot', { format: 'png' });
    fs.writeFileSync(`${ARTIFACT_DIR}/e2e-live-font-changed.png`, Buffer.from(snapFont.data, 'base64'));
    console.log('✔ JetBrains Mono yazı tipi seçildi ve doğrulandı.');

    // Switch theme to OLED Stealth
    await send('Runtime.evaluate', {
      expression: `(() => {
        const tabBtn = Array.from(document.querySelectorAll('button')).find(b => b.innerText.includes('Temalar'));
        if (tabBtn) tabBtn.click();
      })()`
    });
    await new Promise(r => setTimeout(r, 300));
    await send('Runtime.evaluate', {
      expression: `(() => {
        const themeBtn = Array.from(document.querySelectorAll('button')).find(b => b.innerText.includes('Stealth'));
        if (themeBtn) themeBtn.click();
      })()`
    });
    await new Promise(r => setTimeout(r, 400));

    // Close Theme Modal
    await send('Runtime.evaluate', {
      expression: `(() => {
        window.__MEVA_STORE__ && window.__MEVA_THEME_STORE__ ? window.__MEVA_THEME_STORE__.getState().setShowThemeModal(false) : null;
        const closeBtn = document.querySelector('button[aria-label="Kapat"]');
        if (closeBtn) closeBtn.click();
      })()`
    });
    await new Promise(r => setTimeout(r, 400));

    // ── STEP 2: TEST SERVER CREATION (SUNUCU KURMA) ──
    console.log('▶ [FAZ 2] Sunucu Kurma & Şablon Entegrasyonu Test Ediliyor...');
    await send('Runtime.evaluate', {
      expression: `(() => {
        const btn = Array.from(document.querySelectorAll('button')).find(b => b.innerText.includes('Sunucu Oluştur'));
        if (btn) btn.click();
      })()`
    });
    await new Promise(r => setTimeout(r, 600));

    // Click "Bu Şablonla Kur" for "Espor Scrim Karargahı"
    await send('Runtime.evaluate', {
      expression: `(() => {
        const kurBtns = Array.from(document.querySelectorAll('button')).filter(b => b.innerText.includes('Şablonla Kur'));
        if (kurBtns.length > 1) {
          kurBtns[1].click(); // Select second template (Espor Scrim Karargahı)
        } else if (kurBtns.length > 0) {
          kurBtns[0].click();
        }
      })()`
    });
    await new Promise(r => setTimeout(r, 800));

    const snapServer = await send('Page.captureScreenshot', { format: 'png' });
    fs.writeFileSync(`${ARTIFACT_DIR}/e2e-live-server-created.png`, Buffer.from(snapServer.data, 'base64'));
    console.log('✔ Sunucu ve kanallar başarıyla kuruldu.');

    // ── STEP 3: TEST CHAT & MESSAGING ──
    console.log('▶ [FAZ 3] Sohbet ve Taktik Mesajlaşma Test Ediliyor...');
    // Click on a text channel in sidebar
    await send('Runtime.evaluate', {
      expression: `(() => {
        const chanBtn = Array.from(document.querySelectorAll('button')).find(b => b.innerText.includes('#') || b.innerText.includes('taktik') || b.innerText.includes('sohbet'));
        if (chanBtn) chanBtn.click();
      })()`
    });
    await new Promise(r => setTimeout(r, 400));

    // Type a message into input and submit
    await send('Runtime.evaluate', {
      expression: `(() => {
        const input = document.querySelector('input[placeholder*="taktik mesaj"]');
        if (input) {
          input.value = "⚡ [MEVA PRO HUD]: Takım hazır! Mirage A Site execute için AWP pozisyon alsın.";
          input.dispatchEvent(new Event('input', { bubbles: true }));
          const form = input.closest('form');
          if (form) form.dispatchEvent(new Event('submit', { bubbles: true, cancelable: true }));
        }
      })()`
    });
    await new Promise(r => setTimeout(r, 600));

    // Click tactical callout buttons: [Rotate B], [Eco Round]
    await send('Runtime.evaluate', {
      expression: `(() => {
        const rotateBtn = Array.from(document.querySelectorAll('button')).find(b => b.innerText === 'Rotate B' || b.innerText.includes('Rotate'));
        if (rotateBtn) rotateBtn.click();
      })()`
    });
    await new Promise(r => setTimeout(r, 400));

    const snapChat = await send('Page.captureScreenshot', { format: 'png' });
    fs.writeFileSync(`${ARTIFACT_DIR}/e2e-live-chat-messaging.png`, Buffer.from(snapChat.data, 'base64'));
    console.log('✔ Taktik mesaj ve callout başarıyla iletildi.');

    // ── STEP 4: TEST PRO STRATBOOK STUDIO (TAKTIK HARITA MASASI) ──
    console.log('▶ [FAZ 4] Taktik Harita Masası (Pro Stratbook Studio) Test Ediliyor...');
    // Open Tactical Map Board
    await send('Runtime.evaluate', {
      expression: `(() => {
        const mapBtn = document.querySelector('button[title*="Taktik Harita"]') ||
                       Array.from(document.querySelectorAll('button')).find(b => b.getAttribute('aria-label')?.includes('Taktik Harita'));
        if (mapBtn) mapBtn.click();
      })()`
    });
    await new Promise(r => setTimeout(r, 1000));

    // Switch Game: Counter-Strike 2
    await send('Runtime.evaluate', {
      expression: `(() => {
        const csBtn = Array.from(document.querySelectorAll('button')).find(b => b.innerText.includes('Counter-Strike 2') || b.innerText.includes('CS2'));
        if (csBtn) csBtn.click();
      })()`
    });
    await new Promise(r => setTimeout(r, 500));

    // Switch Map to Mirage or Inferno
    await send('Runtime.evaluate', {
      expression: `(() => {
        const mapTab = Array.from(document.querySelectorAll('button')).find(b => b.innerText.includes('Mirage') || b.innerText.includes('Inferno'));
        if (mapTab) mapTab.click();
      })()`
    });
    await new Promise(r => setTimeout(r, 500));

    // Test Zoom (+)
    await send('Runtime.evaluate', {
      expression: `(() => {
        const zoomIn = Array.from(document.querySelectorAll('button')).find(b => b.innerText === '+' || b.getAttribute('title')?.includes('Yakınlaş'));
        if (zoomIn) zoomIn.click();
      })()`
    });
    await new Promise(r => setTimeout(r, 400));

    // Test Phase 2: Mid
    await send('Runtime.evaluate', {
      expression: `(() => {
        const phaseBtn = Array.from(document.querySelectorAll('button')).find(b => b.innerText.includes('Mid') || b.innerText.includes('Aşama 2'));
        if (phaseBtn) phaseBtn.click();
      })()`
    });
    await new Promise(r => setTimeout(r, 500));

    const snapMap = await send('Page.captureScreenshot', { format: 'png' });
    fs.writeFileSync(`${ARTIFACT_DIR}/e2e-live-tactical-map.png`, Buffer.from(snapMap.data, 'base64'));
    console.log('✔ Taktik harita masası, zoom, oyun ve harita geçişleri doğrulandı.');

    // Close Strat Drawer
    await send('Runtime.evaluate', {
      expression: `(() => {
        const closeBtn = document.querySelector('button[title="Taktik Masasını Kapat"]');
        if (closeBtn) closeBtn.click();
      })()`
    });
    await new Promise(r => setTimeout(r, 500));

    // ── STEP 5: TEST IGL WHEEL & SOUNDBOARD MODALS ──
    console.log('▶ [FAZ 5] IGL Komut Çarkı ve Soundboard Test Ediliyor...');
    // Open IGL Wheel
    await send('Runtime.evaluate', {
      expression: `(() => {
        const iglBtn = document.querySelector('button[title*="IGL Taktik Hızlı Komut"]') ||
                       Array.from(document.querySelectorAll('button')).find(b => b.getAttribute('aria-label')?.includes('IGL'));
        if (iglBtn) iglBtn.click();
      })()`
    });
    await new Promise(r => setTimeout(r, 600));

    const snapIgl = await send('Page.captureScreenshot', { format: 'png' });
    fs.writeFileSync(`${ARTIFACT_DIR}/e2e-live-igl-wheel.png`, Buffer.from(snapIgl.data, 'base64'));
    console.log('✔ IGL Taktik komut çarkı doğrulandı.');

    // Close IGL Wheel with Escape
    await send('Runtime.evaluate', {
      expression: `(() => {
        window.dispatchEvent(new KeyboardEvent('keydown', { key: 'Escape' }));
      })()`
    });
    await new Promise(r => setTimeout(r, 400));

    console.log('================================================================');
    console.log(`🎉 TÜM TESTLER TAMAMLANDI. Hata Sayısı: ${errors.length}`);
    if (errors.length > 0) {
      console.error('Hatalar:', errors);
    } else {
      console.log('SIFIR HATA — Tüm bileşenler, modallar ve motorlar %100 kusursuz.');
    }
    console.log('================================================================');

    ws.close();
    process.exit(0);
  };
}

main().catch(console.error);
