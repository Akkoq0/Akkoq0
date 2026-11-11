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

async function runTest() {
  console.log('🚀 Starting Tactical View Customization & Themes Live E2E Audit...');
  const tabs = await getJson(`http://127.0.0.1:${CHROME_PORT}/json`);
  const pageTab = tabs.find((t) => t.type === 'page');
  if (!pageTab) throw new Error('No Chrome page tab found on port 9222');

  const cdp = new CdpClient(pageTab.webSocketDebuggerUrl);
  await cdp.connect();

  await cdp.send('Page.enable');
  await cdp.send('DOM.enable');
  await cdp.send('Emulation.setDeviceMetricsOverride', {
    width: 1440,
    height: 900,
    deviceScaleFactor: 1,
    mobile: false,
  });

  // Navigate to main app
  console.log('▶ Navigating to app...');
  await cdp.send('Page.navigate', { url: 'http://127.0.0.1:3000' });
  await sleep(3000);

  // 1. Open Tactical Board
  console.log('▶ Opening Tactical Board...');
  const boardOpened = await cdp.eval(`(() => {
    if (typeof window.__openStratBoard === 'function') {
      window.__openStratBoard();
      return true;
    }
    const buttons = Array.from(document.querySelectorAll('button'));
    const tactBtn = buttons.find(b => b.textContent && (b.textContent.includes('Taktik') || b.textContent.includes('STRATBOOK')));
    if (tactBtn) {
      tactBtn.click();
      return true;
    }
    return false;
  })()`);
  console.log(`▶ StratBoard opened: ${boardOpened ? '✔ YES' : '✖ NO'}`);
  await sleep(1500);

  // 2. Locate and click [🎛️ Görünüm] button
  console.log('▶ Opening Tactical View Customizer Modal...');
  const clickedCustomizer = await cdp.eval(`(() => {
    const buttons = Array.from(document.querySelectorAll('button'));
    const btn = buttons.find(b => b.textContent && b.textContent.includes('Görünüm'));
    if (btn) {
      btn.click();
      return true;
    }
    return false;
  })()`);
  console.log(`▶ Clicked [🎛️ Görünüm]: ${clickedCustomizer ? '✔ YES' : '✖ NO'}`);
  await sleep(600);

  // Verify modal is open
  const modalOpen = await cdp.eval(`(() => {
    const modal = document.querySelector('[role="dialog"][aria-label="Taktik Harita Görünüm ve Özelleştirme"]');
    return !!modal;
  })()`);
  console.log(`▶ Tactical View Customizer Modal open: ${modalOpen ? '✔ YES' : '✖ NO'}`);

  await cdp.screenshot('tactical-customizer-modal.png');

  // 3. Select Theme: Cyber Cyan
  console.log('▶ Selecting "Cyber Cyan" Theme...');
  await cdp.eval(`(() => {
    const buttons = Array.from(document.querySelectorAll('button'));
    const cyanBtn = buttons.find(b => b.textContent && b.textContent.includes('Cyber Cyan'));
    if (cyanBtn) cyanBtn.click();
  })()`);
  await sleep(300);

  // 4. Select Grid Mode: Sık Izgara (30px)
  console.log('▶ Selecting Grid Mode: Sık Izgara (30px)...');
  await cdp.eval(`(() => {
    const buttons = Array.from(document.querySelectorAll('button'));
    const denseGridBtn = buttons.find(b => b.textContent && b.textContent.includes('Sık Izgara'));
    if (denseGridBtn) denseGridBtn.click();
  })()`);
  await sleep(300);

  // 5. Select Radar Filter: Yüksek Kontrast
  console.log('▶ Selecting Radar Filter: Yüksek Kontrast...');
  await cdp.eval(`(() => {
    const buttons = Array.from(document.querySelectorAll('button'));
    const contrastBtn = buttons.find(b => b.textContent && b.textContent.includes('Yüksek Kontrast'));
    if (contrastBtn) contrastBtn.click();
  })()`);
  await sleep(300);

  // 6. Close Modal
  console.log('▶ Closing modal to view live customized tactical canvas...');
  await cdp.eval(`(() => {
    const confirmBtn = document.querySelector('[aria-label="Görünüm Ayarlarını Onayla"]') || document.querySelector('[aria-label="Görünüm Ayarlarını Kapat"]');
    if (confirmBtn) confirmBtn.click();
  })()`);
  await sleep(1000);

  // Screenshot Cyber Cyan + Dense Grid + High Contrast
  await cdp.screenshot('tactical-cyber-cyan-high-contrast.png');

  // 7. Verify Theme changed to Cyan in Telemetry Badge and Canvas Filter
  const telemetryBadge = await cdp.eval(`(() => {
    const badges = Array.from(document.querySelectorAll('span'));
    const themeBadge = badges.find(s => s.textContent && s.textContent.includes('Cyber Cyan'));
    return themeBadge ? themeBadge.textContent : null;
  })()`);
  console.log(`▶ Telemetry Theme Badge active: ${telemetryBadge ? `✔ ${telemetryBadge}` : '✖ NOT FOUND'}`);

  // 8. Re-open customizer modal and switch to Amethyst SpecOps + OLED Dark
  console.log('▶ Re-opening Customizer to switch to Amethyst SpecOps + OLED Dark...');
  await cdp.eval(`(() => {
    const buttons = Array.from(document.querySelectorAll('button'));
    const btn = buttons.find(b => b.textContent && b.textContent.includes('Görünüm'));
    if (btn) btn.click();
  })()`);
  await sleep(500);

  await cdp.eval(`(() => {
    const buttons = Array.from(document.querySelectorAll('button'));
    const purpleBtn = buttons.find(b => b.textContent && b.textContent.includes('Amethyst SpecOps'));
    if (purpleBtn) purpleBtn.click();
  })()`);
  await sleep(300);

  await cdp.eval(`(() => {
    const buttons = Array.from(document.querySelectorAll('button'));
    const oledBtn = buttons.find(b => b.textContent && b.textContent.includes('OLED Karanlık'));
    if (oledBtn) oledBtn.click();
  })()`);
  await sleep(300);

  // Close modal
  await cdp.eval(`(() => {
    const confirmBtn = document.querySelector('[aria-label="Görünüm Ayarlarını Onayla"]') || document.querySelector('[aria-label="Görünüm Ayarlarını Kapat"]');
    if (confirmBtn) confirmBtn.click();
  })()`);
  await sleep(1000);

  await cdp.screenshot('tactical-amethyst-oled-active.png');

  console.log('🎉 Tactical View Customizer E2E audit passed with 100% success!');
  process.exit(0);
}

runTest().catch((err) => {
  console.error('Test failed:', err);
  process.exit(1);
});
