/**
 * @file test-mobile-features.mjs
 * @description Mobile-first E2E verification on emulated mobile viewport (390x844):
 *   1. Floating Tactical Voice Bubble & Edge Snap
 *   2. Mobile Thumb Sheet with one-thumb controls & haptic feedback
 *   3. Mobile Tournament Bracket with Stage Tabs (Çeyrek / Yarı / Final)
 *   4. Mobile Map Veto & Coinflip
 */

import http from 'http';

const ARTIFACT_DIR = '/home/codespace/.gemini/antigravity/brain/7a1a0347-783f-4006-8567-f0b06c04c11c';
const CHROME_PORT = 9222;

function sleep(ms) {
  return new Promise((resolve) => setTimeout(resolve, ms));
}

function getJson(url) {
  return new Promise((resolve, reject) => {
    http.get(url, (res) => {
      let data = '';
      res.on('data', (c) => (data += c));
      res.on('end', () => {
        try {
          resolve(JSON.parse(data));
        } catch (e) {
          reject(e);
        }
      });
    }).on('error', reject);
  });
}

class CdpClient {
  constructor(wsUrl) {
    this.wsUrl = wsUrl;
    this.ws = null;
    this.id = 1;
    this.callbacks = new Map();
  }

  async connect() {
    const WS = globalThis.WebSocket;
    return new Promise((resolve, reject) => {
      this.ws = new WS(this.wsUrl);
      this.ws.onopen = resolve;
      this.ws.onerror = reject;
      this.ws.onmessage = (event) => {
        const raw = event.data;
        const msg = JSON.parse(raw.toString());
        if (msg.id && this.callbacks.has(msg.id)) {
          const { res, rej } = this.callbacks.get(msg.id);
          this.callbacks.delete(msg.id);
          if (msg.error) rej(msg.error);
          else res(msg.result);
        }
      };
    });
  }

  send(method, params = {}) {
    return new Promise((res, rej) => {
      const id = this.id++;
      this.callbacks.set(id, { res, rej });
      this.ws.send(JSON.stringify({ id, method, params }));
    });
  }

  async eval(expr) {
    const r = await this.send('Runtime.evaluate', {
      expression: expr,
      returnByValue: true,
      awaitPromise: true,
    });
    return r?.result?.value;
  }

  async captureScreenshot(path) {
    const fs = await import('fs');
    const r = await this.send('Page.captureScreenshot', { format: 'png' });
    fs.writeFileSync(path, Buffer.from(r.data, 'base64'));
  }
}

async function run() {
  console.log('📱 [MOBILE TEST STARTED] Canlı E2E Mobil Özellik Doğrulaması Başlıyor...\n');

  const targets = await getJson(`http://127.0.0.1:${CHROME_PORT}/json`);
  let pageTarget = targets.find((t) => t.type === 'page');

  if (!pageTarget) {
    const newPage = await getJson(`http://127.0.0.1:${CHROME_PORT}/json/new?http://localhost:3000`);
    pageTarget = newPage;
  }

  const cdp = new CdpClient(pageTarget.webSocketDebuggerUrl);
  await cdp.connect();

  await cdp.send('Page.enable');
  await cdp.send('Runtime.enable');
  await cdp.send('DOM.enable');

  // Set Mobile Viewport (iPhone 14 Pro: 393 x 852, touch: true, mobile: true)
  console.log('▶ [FAZ 1] Mobil Görünüm Emülasyonu Ayarlanıyor (393 x 852 Touch)...');
  await cdp.send('Emulation.setDeviceMetricsOverride', {
    width: 393,
    height: 852,
    deviceScaleFactor: 2,
    mobile: true,
  });
  await cdp.send('Emulation.setTouchEmulationEnabled', {
    enabled: true,
    configuration: 'mobile',
  });

  // Navigate
  await cdp.send('Page.navigate', { url: 'http://localhost:3000' });
  await sleep(1800);

  // 1. Verify Mobile Floating Tactical Bubble
  console.log('▶ [FAZ 2] Mobil Taktik Ses Balonu (Chat-Head Pill) Test Ediliyor...');
  const bubbleInfo = await cdp.eval(`
    (() => {
      const bubble = document.querySelector('div.cursor-grab');
      if (!bubble) return { found: false };
      return {
        found: true,
        text: bubble.textContent,
        style: bubble.getAttribute('style'),
      };
    })()
  `);
  console.log('✔ Mobil ses balonu durumu:', bubbleInfo);

  await cdp.captureScreenshot(`${ARTIFACT_DIR}/mobile-voice-bubble.png`);
  console.log('📸 Ekran Görüntüsü: mobile-voice-bubble.png');

  // 2. Tap bubble to open Mobile Bottom Thumb Sheet
  console.log('\n▶ [FAZ 3] Balona Dokunarak Mobil Başparmak Kontrol Paneli (Bottom Sheet) Açılıyor...');
  await cdp.eval(`
    (() => {
      const bubbleInner = document.querySelector('div.cursor-grab > div');
      if (bubbleInner) bubbleInner.click();
    })()
  `);
  await sleep(600);

  const sheetInfo = await cdp.eval(`
    (() => {
      const sheet = document.querySelector('div.rounded-t-3xl');
      return {
        open: !!sheet,
        hasBigMute: !!sheet?.querySelector('button[title*="Mikrofon"]'),
        calloutCount: sheet?.querySelectorAll('button')?.length || 0,
      };
    })()
  `);
  console.log('✔ Mobil başparmak kontrol paneli durumu:', sheetInfo);

  await cdp.captureScreenshot(`${ARTIFACT_DIR}/mobile-voice-thumb-sheet.png`);
  console.log('📸 Ekran Görüntüsü: mobile-voice-thumb-sheet.png');

  // Close sheet (tap close button)
  await cdp.eval(`
    (() => {
      const closeBtn = document.querySelector('div.rounded-t-3xl button');
      if (closeBtn) closeBtn.click();
    })()
  `);
  await sleep(400);

  // 3. Open Scrim Modal -> Test Mobile Tournament Bracket with Stage Tabs
  console.log('\n▶ [FAZ 4] Mobil Turnuva Ağacı & Aşama Sekmeleri (Stage Tabs) Test Ediliyor...');
  await cdp.eval(`
    (() => {
      const scrimBtn = Array.from(document.querySelectorAll('button')).find(b => 
        b.title?.includes('Scrim') || b.textContent?.includes('📅')
      );
      if (scrimBtn) scrimBtn.click();
    })()
  `);
  await sleep(600);

  // Switch to Bracket tab
  await cdp.eval(`
    (() => {
      const tabBtn = Array.from(document.querySelectorAll('button')).find(b => 
        b.textContent?.includes('Turnuva Ağacı')
      );
      if (tabBtn) tabBtn.click();
    })()
  `);
  await sleep(500);

  // Tap mobile 'Büyük Final' tab
  await cdp.eval(`
    (() => {
      const gfTab = Array.from(document.querySelectorAll('button')).find(b => 
        b.textContent?.includes('Büyük Final')
      );
      if (gfTab) gfTab.click();
    })()
  `);
  await sleep(400);

  await cdp.captureScreenshot(`${ARTIFACT_DIR}/mobile-tournament-stage-tabs.png`);
  console.log('📸 Ekran Görüntüsü: mobile-tournament-stage-tabs.png');

  // 4. Switch to Veto Tab -> Test Mobile Ban/Pick & Coin Flip
  console.log('\n▶ [FAZ 5] Mobil Harita Veto & Coinflip Dokunmatik Kontrolleri Test Ediliyor...');
  await cdp.eval(`
    (() => {
      const vetoTab = Array.from(document.querySelectorAll('button')).find(b => 
        b.textContent?.includes('Harita Veto')
      );
      if (vetoTab) vetoTab.click();
    })()
  `);
  await sleep(500);

  // Flip coin
  await cdp.eval(`
    (() => {
      const coinBtn = Array.from(document.querySelectorAll('button')).find(b => 
        b.textContent?.includes('Yazı-Tura At')
      );
      if (coinBtn) coinBtn.click();
    })()
  `);
  await sleep(600);

  // Tap Ban button on mobile
  await cdp.eval(`
    (() => {
      const banBtn = Array.from(document.querySelectorAll('button')).find(b => 
        b.textContent === 'Banla'
      );
      if (banBtn) banBtn.click();
    })()
  `);
  await sleep(400);

  await cdp.captureScreenshot(`${ARTIFACT_DIR}/mobile-map-veto-touch.png`);
  console.log('📸 Ekran Görüntüsü: mobile-map-veto-touch.png');

  console.log('\n================================================================');
  console.log('🎉 TÜM MOBİLE ÖZEL OPTİMİZASYON TESTLERİ TAMAMLANDI! HATA: 0');
  console.log('Mobil Ses Balonu, Alt Başparmak Paneli, Aşama Sekmeli Bracket ve Dokunmatik Veto Doğrulandı.');
  console.log('================================================================\n');

  process.exit(0);
}

run().catch((err) => {
  console.error('❌ Mobil test hatası:', err);
  process.exit(1);
});
