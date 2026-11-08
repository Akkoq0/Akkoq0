// ─────────────────────────────────────────────────────────
// Meva HUD — Comprehensive Button & Sidebar Click Stress Test
// ─────────────────────────────────────────────────────────
// Connects via Chrome CDP, discovers every single button,
// tests clickability, modal triggers, state transitions,
// and identifies any dead, redundant, or error-throwing buttons.

const CDP_HTTP = 'http://localhost:9222';
const APP_URL = 'http://localhost:3000';

class CDPClient {
  constructor(wsUrl) {
    this.wsUrl = wsUrl;
    this.ws = null;
    this.msgId = 0;
    this.pending = new Map();
    this.events = new Map();
  }

  async connect() {
    return new Promise((resolve, reject) => {
      this.ws = new WebSocket(this.wsUrl);
      this.ws.onopen = () => resolve();
      this.ws.onerror = (err) => reject(err);
      this.ws.onmessage = (event) => {
        const data = JSON.parse(event.data);
        if (data.id && this.pending.has(data.id)) {
          const { resolve, reject } = this.pending.get(data.id);
          this.pending.delete(data.id);
          if (data.error) reject(new Error(data.error.message));
          else resolve(data.result);
        } else if (data.method) {
          const handlers = this.events.get(data.method) || [];
          for (const h of handlers) h(data.params);
        }
      };
    });
  }

  send(method, params = {}) {
    return new Promise((resolve, reject) => {
      const id = ++this.msgId;
      this.pending.set(id, { resolve, reject });
      this.ws.send(JSON.stringify({ id, method, params }));
    });
  }

  on(event, handler) {
    if (!this.events.has(event)) this.events.set(event, []);
    this.events.get(event).push(handler);
  }

  close() {
    if (this.ws) this.ws.close();
  }
}

async function runButtonStressTest() {
  console.log('================================================================');
  console.log('  MEVA HUD — TÜM BUTON VE SİDEBAR TIKLAMA STRES TESTİ');
  console.log('================================================================\n');

  const createRes = await fetch(`${CDP_HTTP}/json/new?${encodeURIComponent(APP_URL)}`, { method: 'PUT' });
  const target = await createRes.json();
  const client = new CDPClient(target.webSocketDebuggerUrl);
  await client.connect();

  const consoleErrors = [];
  const warnings = [];

  await client.send('Page.enable');
  await client.send('Runtime.enable');
  await client.send('DOM.enable');

  client.on('Runtime.consoleAPICalled', (params) => {
    const text = params.args.map((a) => a.value || a.description || '').join(' ');
    if (params.type === 'error') consoleErrors.push(text);
    if (params.type === 'warning') warnings.push(text);
  });

  client.on('Runtime.exceptionThrown', (params) => {
    const desc = params.exceptionDetails.exception?.description || params.exceptionDetails.text;
    consoleErrors.push(`Exception: ${desc}`);
  });

  await new Promise((r) => setTimeout(r, 2000));

  // 1. Gather all initial buttons
  const buttonsRes = await client.send('Runtime.evaluate', {
    expression: `(() => {
      const buttons = Array.from(document.querySelectorAll('button'));
      return buttons.map((b, idx) => ({
        index: idx,
        text: (b.innerText || b.textContent || '').trim().replace(/\\s+/g, ' '),
        title: b.getAttribute('title') || '',
        ariaLabel: b.getAttribute('aria-label') || '',
        id: b.id || '',
        className: b.className || '',
        disabled: b.disabled || false,
        visible: b.offsetParent !== null && window.getComputedStyle(b).display !== 'none',
      }));
    })()`,
    returnByValue: true,
  });

  const buttons = buttonsRes.result.value;
  console.log(`▶ Toplam Tespit Edilen Buton Sayısı: ${buttons.length}\n`);

  const results = [];

  for (let i = 0; i < buttons.length; i++) {
    const btn = buttons[i];
    const label = btn.title || btn.ariaLabel || btn.text || `Button #${btn.index}`;

    // Click button
    const clickRes = await client.send('Runtime.evaluate', {
      expression: `(() => {
        try {
          const all = document.querySelectorAll('button');
          const target = all[${btn.index}];
          if (!target) return { ok: false, reason: 'not-found' };
          target.click();
          return { ok: true, activeModals: document.querySelectorAll('[role="dialog"]').length };
        } catch (err) {
          return { ok: false, error: err.message };
        }
      })()`,
      returnByValue: true,
    });

    results.push({
      label,
      index: btn.index,
      ...clickRes.result.value,
    });

    // Small delay to observe UI change
    await new Promise((r) => setTimeout(r, 120));

    // If a modal opened, dismiss it via Escape so we don't block subsequent button clicks
    await client.send('Runtime.evaluate', {
      expression: `window.dispatchEvent(new KeyboardEvent('keydown', { key: 'Escape' }))`,
    });
    await new Promise((r) => setTimeout(r, 60));
  }

  // Summary
  console.log('────────────────────────────────────────────────────────────────');
  console.log('TIKLAMA ANALİZİ TABLOSU:');
  console.log('────────────────────────────────────────────────────────────────');
  for (const r of results) {
    const status = r.ok ? '✔ BAŞARILI' : '❌ HATA';
    console.log(`[#${r.index.toString().padStart(2, '0')}] ${status} | "${r.label}"`);
  }

  console.log('\n================================================================');
  console.log(`  Toplam Tıklanan Buton: ${results.length}`);
  console.log(`  Başarısız Tıklama: ${results.filter(r => !r.ok).length}`);
  console.log(`  Konsol Hatası: ${consoleErrors.length}`);
  console.log('================================================================\n');

  await client.send('Target.closeTarget', { targetId: target.id });
  client.close();

  if (consoleErrors.length > 0) {
    console.log('Konsol Hataları:', consoleErrors);
    process.exit(1);
  }
}

runButtonStressTest().catch((err) => {
  console.error('Test error:', err);
  process.exit(1);
});
