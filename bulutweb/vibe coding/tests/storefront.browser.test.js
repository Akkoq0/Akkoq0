const test = require('node:test');
const assert = require('node:assert/strict');
const { chromium } = require('playwright');

process.env.NODE_ENV = 'test';
process.env.DB_PATH = ':memory:';
process.env.ADMIN_USERNAME = 'browser-test-admin';
process.env.ADMIN_PASSWORD = 'browser-test-password';

const { app, initDatabase, getDb } = require('../server');

test('storefront supports category, stock, Shopier link, and demo checkout on desktop and mobile', async (context) => {
  let browser;
  try {
    browser = await chromium.launch({ headless: true });
  } catch (error) {
    context.skip(`Chromium sistem bağımlılığı eksik: ${error.message.split('\n')[0]}`);
    return;
  }

  await initDatabase();
  await new Promise((resolve, reject) => {
    getDb().run('UPDATE products SET stock = 5 WHERE id = 1', (error) => error ? reject(error) : resolve());
  });
  await new Promise((resolve, reject) => {
    getDb().run('UPDATE products SET stock = 2, payment_url = ? WHERE id = 2', [
      'https://www.shopier.com/ShowProductNew/products.php?id=456'
    ], (error) => error ? reject(error) : resolve());
  });

  const server = app.listen(0, '127.0.0.1');
  await new Promise((resolve) => server.once('listening', resolve));
  const baseUrl = `http://127.0.0.1:${server.address().port}`;
  const page = await browser.newPage({ viewport: { width: 1440, height: 1000 } });
  const pageErrors = [];
  page.on('pageerror', (error) => pageErrors.push(error.message));

  try {
    await page.goto(baseUrl);
    await page.locator('.product-card').first().waitFor();
    await page.screenshot({ path: '/tmp/timenest-desktop.png', fullPage: true });

    await page.locator('[data-filter-category="Günlük"]').click();
    assert.equal(await page.locator('.product-card').count(), 1);
    assert.match(await page.locator('.product-card h3').textContent(), /City Drift/);

    await page.getByRole('button', { name: 'Hepsi' }).click();
    const shopierLink = page.getByRole('link', { name: "Shopier'de satın al" });
    await shopierLink.first().waitFor();
    assert.match(await shopierLink.first().getAttribute('href'), /^https:\/\/([a-z0-9-]+\.)*shopier\.com\//);
    assert.ok(await page.locator('button.add-btn:disabled').count() > 0);

    await page.locator('button.add-btn:not(:disabled)').first().click();
    await page.goto(`${baseUrl}/cart.html`);
    assert.match(await page.locator('#cartItems').textContent(), /Aero Classic/);
    assert.match(await page.locator('.demo-notice').textContent(), /kartınızdan ücret alınmaz/);

    await page.locator('[name="name"]').fill('Tarayıcı Testi');
    await page.locator('[name="email"]').fill('browser@example.com');
    await page.locator('[name="address"]').fill('Test adresi');
    await page.locator('[name="city"]').fill('İstanbul');
    await page.locator('[name="phone"]').fill('05550000000');
    await page.getByRole('button', { name: 'Deneme siparişi oluştur' }).click();
    await page.waitForURL(/checkout-success\.html/);
    assert.match(await page.locator('body').textContent(), /Deneme siparişi kaydedildi/);
    assert.match(await page.locator('#successOrderId').textContent(), /^\d+$/);

    await page.setViewportSize({ width: 390, height: 844 });
    await page.goto(baseUrl);
    await page.locator('.product-card').first().waitFor();
    const mobileMenuButton = page.getByRole('button', { name: 'Menü' });
    await mobileMenuButton.click();
    assert.equal(await mobileMenuButton.getAttribute('aria-expanded'), 'true');
    await page.locator('#siteMenu').getByRole('link', { name: 'Ürünler' }).waitFor();
    await page.screenshot({ path: '/tmp/timenest-mobile.png', fullPage: true });

    await page.route('**/api/store-config', (route) => route.fulfill({
      status: 200,
      contentType: 'application/json',
      body: JSON.stringify({ demoCheckoutEnabled: false })
    }));
    await page.goto(`${baseUrl}/login`);
    await page.locator('[name="username"]').fill('browser-test-admin');
    await page.locator('[name="password"]').fill('browser-test-password');
    await page.getByRole('button', { name: 'Giriş yap' }).click();
    await page.waitForURL(/\/admin$/);

    await page.goto(baseUrl);
    await page.evaluate(() => localStorage.setItem('timenest-cart', JSON.stringify([{ id: 1, quantity: 1 }])));
    for (const width of [320, 360, 390, 768]) {
      await page.setViewportSize({ width, height: 844 });
      for (const route of ['/', '/cart.html', '/product-detail.html?id=1', '/login', '/legal.html', '/admin']) {
        await page.goto(`${baseUrl}${route}`);
        if (route === '/cart.html') {
          await page.locator('.cart-item').first().waitFor();
          assert.equal(await page.locator('.cart-item').count(), 1);
        }
        const dimensions = await page.evaluate(() => ({
          viewport: document.documentElement.clientWidth,
          content: document.documentElement.scrollWidth
        }));
        assert.ok(
          dimensions.content <= dimensions.viewport,
          `Horizontal overflow at ${width}px on ${route}: ${dimensions.content}px > ${dimensions.viewport}px`
        );
      }
    }
    await page.goto(`${baseUrl}/cart.html`);
    await page.locator('#checkoutUnavailable').waitFor({ state: 'visible' });
    assert.equal(await page.locator('.checkout-panel').isVisible(), false);
    assert.match(await page.locator('#checkoutUnavailable').textContent(), /canlı mağazada kapalı/);
    assert.deepEqual(pageErrors, []);
  } finally {
    await browser.close();
    await new Promise((resolve, reject) => server.close((error) => error ? reject(error) : resolve()));
  }
});