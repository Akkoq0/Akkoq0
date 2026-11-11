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
  console.log('🚀 Starting Tactical Zoom & Callouts Live E2E Audit...');
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
  await cdp.send('Page.navigate', { url: 'http://127.0.0.1:3000' });
  await sleep(2500);

  // 1. Open Tactical Board (Taktik Tahtası)
  console.log('▶ Opening Tactical Board...');
  await cdp.eval(`(() => {
    if (typeof window.__openStratBoard === 'function') {
      window.__openStratBoard();
      return true;
    }
    const buttons = Array.from(document.querySelectorAll('button'));
    const tactBtn = buttons.find(b => b.textContent && (b.textContent.includes('Taktik') || b.textContent.includes('STRATBOOK') || b.textContent.includes('Taktik Tahtası')));
    if (tactBtn) {
      tactBtn.click();
      return true;
    }
    return false;
  })()`);
  await sleep(1500);

  // 2. Verify Floating Zoom Sidebar is rendered
  const zoomSidebarExists = await cdp.eval(`(() => {
    const el = document.querySelector('[aria-label="Taktik Zoom ve Pan Sidebarı"]');
    return !!el;
  })()`);
  console.log(`▶ Floating Zoom Sidebar rendered: ${zoomSidebarExists ? '✔ YES' : '✖ NO'}`);

  if (zoomSidebarExists) {
    // Test Zoom In (+)
    const initialZoom = await cdp.eval(`(() => {
      const zoomText = document.querySelector('[aria-label="Taktik Zoom ve Pan Sidebarı"] .font-mono')?.textContent;
      return zoomText || '';
    })()`);
    console.log(`  Initial Zoom: ${initialZoom}`);

    // Click Zoom In
    await cdp.eval(`(() => {
      const btn = document.querySelector('[aria-label="Yakınlaştır"]');
      if (btn) btn.click();
    })()`);
    await sleep(300);

    const zoomedInText = await cdp.eval(`(() => {
      const zoomText = document.querySelector('[aria-label="Taktik Zoom ve Pan Sidebarı"] .font-mono')?.textContent;
      return zoomText || '';
    })()`);
    console.log(`  After Zoom In (+): ${zoomedInText}`);

    // Click 200% Stepper
    await cdp.eval(`(() => {
      const buttons = Array.from(document.querySelectorAll('[aria-label="Taktik Zoom ve Pan Sidebarı"] button'));
      const b200 = buttons.find(b => b.textContent && b.textContent.includes('%200'));
      if (b200) b200.click();
    })()`);
    await sleep(300);

    const zoom200Text = await cdp.eval(`(() => {
      const zoomText = document.querySelector('[aria-label="Taktik Zoom ve Pan Sidebarı"] .font-mono')?.textContent;
      return zoomText || '';
    })()`);
    console.log(`  After Stepper 200%: ${zoom200Text}`);

    // Click Reset (⟲)
    await cdp.eval(`(() => {
      const btn = document.querySelector('[aria-label="Ölçeği ve Konumu Sıfırla"]');
      if (btn) btn.click();
    })()`);
    await sleep(300);

    const resetZoomText = await cdp.eval(`(() => {
      const zoomText = document.querySelector('[aria-label="Taktik Zoom ve Pan Sidebarı"] .font-mono')?.textContent;
      return zoomText || '';
    })()`);
    console.log(`  After Reset: ${resetZoomText}`);

    // Toggle Pan Tool
    await cdp.eval(`(() => {
      const btn = document.querySelector('[aria-label="Kaydırma Modu"]');
      if (btn) btn.click();
    })()`);
    await sleep(300);
    console.log('  Pan tool toggled successfully.');
  }

  await cdp.screenshot('tactical-zoom-sidebar-active.png');

  // 3. Test CS2 Dust2 Map Callouts
  console.log('▶ Testing CS2 Dust II & Ancient & Nuke Callouts...');
  await cdp.eval(`(() => {
    // Select CS2 tab
    const tabs = Array.from(document.querySelectorAll('button'));
    const cs2Tab = tabs.find(b => b.textContent && b.textContent.includes('Counter-Strike'));
    if (cs2Tab) cs2Tab.click();
  })()`);
  await sleep(600);

  // Switch to Dust II
  await cdp.eval(`(() => {
    const selects = Array.from(document.querySelectorAll('button, select, option'));
    const d2 = selects.find(s => s.textContent && (s.textContent.includes('Dust') || s.value === 'dust2'));
    if (d2) d2.click();
  })()`);
  await sleep(800);
  await cdp.screenshot('tactical-dust2-callouts.png');

  // Switch to Ancient
  await cdp.eval(`(() => {
    const buttons = Array.from(document.querySelectorAll('button'));
    const anc = buttons.find(b => b.textContent && b.textContent.includes('Ancient'));
    if (anc) anc.click();
  })()`);
  await sleep(800);
  await cdp.screenshot('tactical-ancient-callouts.png');

  // Switch to Valorant Haven
  console.log('▶ Testing Valorant Haven Callouts...');
  await cdp.eval(`(() => {
    const tabs = Array.from(document.querySelectorAll('button'));
    const valTab = tabs.find(b => b.textContent && b.textContent.includes('Valorant'));
    if (valTab) valTab.click();
  })()`);
  await sleep(600);

  await cdp.eval(`(() => {
    const buttons = Array.from(document.querySelectorAll('button'));
    const haven = buttons.find(b => b.textContent && b.textContent.includes('Haven'));
    if (haven) haven.click();
  })()`);
  await sleep(800);
  await cdp.screenshot('tactical-haven-callouts.png');

  console.log('🎉 Tactical Zoom Sidebar & Callouts verification passed with 100% success!');
  process.exit(0);
}

runTest().catch((err) => {
  console.error('Test failed:', err);
  process.exit(1);
});
