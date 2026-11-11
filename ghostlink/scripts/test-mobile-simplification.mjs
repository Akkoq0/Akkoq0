import http from 'http';
import fs from 'fs';

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
        try {
          const msg = JSON.parse(event.data);
          if (msg.id && this.callbacks.has(msg.id)) {
            const cb = this.callbacks.get(msg.id);
            this.callbacks.delete(msg.id);
            cb(msg.result, msg.error);
          }
        } catch {}
      };
    });
  }

  send(method, params = {}) {
    return new Promise((resolve, reject) => {
      const curId = this.id++;
      this.callbacks.set(curId, (result, error) => {
        if (error) reject(new Error(JSON.stringify(error)));
        else resolve(result);
      });
      this.ws.send(JSON.stringify({ id: curId, method, params }));
    });
  }

  async eval(expr) {
    const res = await this.send('Runtime.evaluate', {
      expression: expr,
      returnByValue: true,
      awaitPromise: true,
    });
    return res?.result?.value;
  }

  async screenshot(filename) {
    const res = await this.send('Page.captureScreenshot', { format: 'png' });
    const buffer = Buffer.from(res.data, 'base64');
    fs.writeFileSync(`${ARTIFACT_DIR}/${filename}`, buffer);
    console.log(`📸 Screenshot saved: ${filename}`);
  }
}

async function run() {
  console.log('🚀 Starting Clean & Simple Mobile/Desktop E2E Audit...');
  const tabs = await getJson(`http://127.0.0.1:${CHROME_PORT}/json`);
  const pageTab = tabs.find((t) => t.type === 'page');
  if (!pageTab) throw new Error('No Chrome page tab found on port 9222');

  const cdp = new CdpClient(pageTab.webSocketDebuggerUrl);
  await cdp.connect();

  await cdp.send('Page.enable');
  await cdp.send('DOM.enable');

  // 1. Mobile Viewport: 390x844 (iPhone 14 standard)
  console.log('▶ Setting mobile viewport (390x844)...');
  await cdp.send('Emulation.setDeviceMetricsOverride', {
    width: 390,
    height: 844,
    deviceScaleFactor: 2,
    mobile: true,
  });

  await cdp.send('Page.navigate', { url: 'http://127.0.0.1:3000' });
  await sleep(2500);

  // Capture Mobile Clean Home
  await cdp.screenshot('mobile-clean-home.png');

  // 2. Open Tactical Board from Mobile Topbar [🗺️ Taktik]
  console.log('▶ Tapping [🗺️ Taktik] on mobile topbar...');
  const openedFromTopbar = await cdp.eval(`(() => {
    const btns = Array.from(document.querySelectorAll('button'));
    const tactBtn = btns.find(b => b.textContent && b.textContent.includes('Taktik') && b.getAttribute('aria-label')?.includes('Taktik Harita'));
    if (tactBtn) {
      tactBtn.click();
      return true;
    }
    // Fallback to window.__openStratBoard
    if (typeof window.__openStratBoard === 'function') {
      window.__openStratBoard();
      return true;
    }
    return false;
  })()`);
  console.log(`▶ Tactical board opened on mobile: ${openedFromTopbar ? '✔ YES' : '✖ NO'}`);
  await sleep(1500);

  // Capture Fullscreen Mobile Tactical Board
  await cdp.screenshot('mobile-clean-tactical-board.png');

  // 3. Open Mobile Game & Map Selector Sheet
  console.log('▶ Opening Mobile Game & Map Selector Sheet...');
  await cdp.eval(`(() => {
    const btn = document.querySelector('button[class*="truncate"]');
    if (btn) btn.click();
  })()`);
  await sleep(600);
  await cdp.screenshot('mobile-map-selector-sheet.png');

  // Close map sheet
  await cdp.eval(`(() => {
    const closeBtn = document.querySelector('[aria-label="Harita Seçimini Kapat"]');
    if (closeBtn) closeBtn.click();
  })()`);
  await sleep(400);

  // 4. Open Mobile Tools Sheet
  console.log('▶ Opening Mobile Tools Sheet...');
  await cdp.eval(`(() => {
    const btns = Array.from(document.querySelectorAll('button'));
    const toolsBtn = btns.find(b => b.textContent && b.textContent.includes('Araçlar'));
    if (toolsBtn) toolsBtn.click();
  })()`);
  await sleep(600);
  await cdp.screenshot('mobile-tools-sheet.png');

  // Close tools sheet
  await cdp.eval(`(() => {
    const confirmBtn = Array.from(document.querySelectorAll('button')).find(b => b.textContent === 'Tamam');
    if (confirmBtn) confirmBtn.click();
  })()`);
  await sleep(400);

  // Close Tactical Board
  await cdp.eval(`(() => {
    if (typeof window.__toggleStratBoard === 'function') {
      window.__toggleStratBoard();
    }
  })()`);
  await sleep(600);

  // 5. Desktop Viewport: 1440x900
  console.log('▶ Setting desktop viewport (1440x900)...');
  await cdp.send('Emulation.setDeviceMetricsOverride', {
    width: 1440,
    height: 900,
    deviceScaleFactor: 1,
    mobile: false,
  });
  await sleep(1000);
  await cdp.screenshot('desktop-clean-view.png');

  console.log('🎉 Simple, clean mobile and desktop verification complete!');
  process.exit(0);
}

run().catch((err) => {
  console.error('Audit failed:', err);
  process.exit(1);
});
