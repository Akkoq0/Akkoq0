const test = require('node:test');
const assert = require('node:assert/strict');
const { spawnSync } = require('node:child_process');
const crypto = require('node:crypto');
const path = require('node:path');

process.env.NODE_ENV = 'test';
process.env.DB_PATH = ':memory:';
process.env.ADMIN_USERNAME = 'admin';
process.env.ADMIN_PASSWORD = 'test-only-admin-password';

const { initDatabase, getDb, app } = require('../server');

test('production startup rejects the example admin password', () => {
  const projectRoot = path.join(__dirname, '..');
  const result = spawnSync(process.execPath, ['-e', 'require("./server")'], {
    cwd: projectRoot,
    env: {
      ...process.env,
      NODE_ENV: 'production',
      SITE_URL: 'https://shop.timenest.com',
      SESSION_SECRET: crypto.randomBytes(48).toString('base64url'),
      ADMIN_USERNAME: 'shop-admin',
      ADMIN_PASSWORD: 'replace-with-a-unique-password',
      SHOPIER_PAYMENT_MODE: 'manual-links'
    },
    encoding: 'utf8'
  });

  assert.notEqual(result.status, 0);
  assert.match(result.stderr, /Production yapılandırması geçersiz/);
  assert.doesNotMatch(result.stderr, /replace-with-a-unique-password/);
});

test('production disables demo checkout and advertises the disabled state', () => {
  const projectRoot = path.join(__dirname, '..');
  const result = spawnSync(process.execPath, ['-e', `
    const { app, initDatabase, getDb } = require('./server');
    (async () => {
      await initDatabase();
      const server = app.listen(0, '127.0.0.1');
      try {
        await new Promise((resolve) => server.once('listening', resolve));
        const baseUrl = 'http://127.0.0.1:' + server.address().port;
        const config = await (await fetch(baseUrl + '/api/store-config')).json();
        const checkout = await fetch(baseUrl + '/api/orders', { method: 'POST' });
        console.log(JSON.stringify({ demoCheckoutEnabled: config.demoCheckoutEnabled, checkoutStatus: checkout.status }));
      } finally {
        if (server.listening) {
          await new Promise((resolve, reject) => server.close((error) => error ? reject(error) : resolve()));
        }
        await new Promise((resolve, reject) => getDb().close((error) => error ? reject(error) : resolve()));
      }
    })().catch((error) => { console.error(error); process.exitCode = 1; });
  `], {
    cwd: projectRoot,
    env: {
      ...process.env,
      NODE_ENV: 'production',
      SITE_URL: 'https://shop.timenest.com',
      SESSION_SECRET: crypto.randomBytes(48).toString('base64url'),
      ADMIN_USERNAME: 'shop-admin',
      ADMIN_PASSWORD: 'Secur3-Admin-Key-Only-42!',
      SHOPIER_PAYMENT_MODE: 'manual-links',
      DB_PATH: ':memory:'
    },
    encoding: 'utf8'
  });

  assert.equal(result.status, 0, result.stderr);
  assert.match(result.stdout, /"demoCheckoutEnabled":false,"checkoutStatus":410/);
});

test('database initializes expected tables', async () => {
  const db = await initDatabase();
  const tables = await new Promise((resolve, reject) => {
    db.all("SELECT name FROM sqlite_master WHERE type='table' ORDER BY name", (err, rows) => {
      if (err) return reject(err);
      resolve(rows.map((row) => row.name));
    });
  });

  assert.ok(tables.includes('products'));
  assert.ok(tables.includes('orders'));
  const indexes = await new Promise((resolve, reject) => {
    db.all("SELECT name FROM sqlite_master WHERE type='index' ORDER BY name", (err, rows) => {
      if (err) return reject(err);
      resolve(rows.map((row) => row.name));
    });
  });
  assert.ok(indexes.includes('orders_created_at_idx'));
  assert.ok(indexes.includes('sessions_expires_idx'));
  const productColumns = await new Promise((resolve, reject) => {
    db.all('PRAGMA table_info(products)', (err, rows) => {
      if (err) return reject(err);
      resolve(rows.map((row) => row.name));
    });
  });
  assert.ok(productColumns.includes('payment_url'));
  assert.ok(productColumns.includes('stock'));
  const orderColumns = await new Promise((resolve, reject) => {
    db.all('PRAGMA table_info(orders)', (err, rows) => {
      if (err) return reject(err);
      resolve(rows.map((row) => row.name));
    });
  });
  assert.ok(orderColumns.includes('carrier'));
  assert.ok(orderColumns.includes('tracking_number'));
  assert.ok(orderColumns.includes('stock_reserved'));
});

test('products table is seeded with watch products', async () => {
  const db = getDb();
  const count = await new Promise((resolve, reject) => {
    db.get('SELECT COUNT(*) AS total FROM products', (err, row) => {
      if (err) return reject(err);
      resolve(Number(row.total));
    });
  });

  assert.ok(count >= 4);
});

test('admin API protects private data and calculates order totals from database prices', async () => {
  await initDatabase();
  const server = app.listen(0, '127.0.0.1');
  await new Promise((resolve) => server.once('listening', resolve));
  const baseUrl = `http://127.0.0.1:${server.address().port}`;
  let createdOrderId;
  let manualOrderId;
  let shipmentOrderId;
  let createdProductId;

  try {
    const unauthorizedOrders = await fetch(`${baseUrl}/api/orders`);
    assert.equal(unauthorizedOrders.status, 401);
    assert.equal(unauthorizedOrders.headers.get('x-content-type-options'), 'nosniff');

    const unauthorizedPaidOrder = await fetch(`${baseUrl}/api/admin/orders`, {
      method: 'POST',
      headers: { 'Content-Type': 'application/json' },
      body: JSON.stringify({})
    });
    assert.equal(unauthorizedPaidOrder.status, 401);

    const adminRedirect = await fetch(`${baseUrl}/admin`, { redirect: 'manual' });
    assert.equal(adminRedirect.status, 302);
    assert.equal(adminRedirect.headers.get('location'), '/login');

    const loginPage = await fetch(`${baseUrl}/login`);
    const loginPageHtml = await loginPage.text();
    const loginNonce = loginPage.headers.get('content-security-policy').match(/nonce-([^']+)/)?.[1];
    assert.ok(loginNonce);
    assert.ok(loginPageHtml.includes(`<script nonce="${loginNonce}">`));
    assert.ok(loginPageHtml.includes(`<style nonce="${loginNonce}">`));
    assert.equal(loginPage.headers.get('cache-control'), 'no-store');
    assert.match(loginPage.headers.get('content-security-policy'), /default-src 'self'/);
    assert.match(loginPage.headers.get('content-security-policy'), /object-src 'none'/);
    assert.doesNotMatch(loginPage.headers.get('content-security-policy'), /unsafe-inline/);

    const privateDatabase = await fetch(`${baseUrl}/data/timenest.db`);
    assert.equal(privateDatabase.status, 404);
    const privateAdminPage = await fetch(`${baseUrl}/admin.html`);
    assert.equal(privateAdminPage.status, 404);
    const privateServerSource = await fetch(`${baseUrl}/server.js`);
    assert.equal(privateServerSource.status, 404);

    const login = await fetch(`${baseUrl}/api/login`, {
      method: 'POST',
      headers: { 'Content-Type': 'application/json' },
      body: JSON.stringify({ username: 'admin', password: 'test-only-admin-password' })
    });
    assert.equal(login.status, 200);
    const cookie = login.headers.get('set-cookie').split(';')[0];

    const adminPage = await fetch(`${baseUrl}/admin`, { headers: { Cookie: cookie } });
    const adminPageHtml = await adminPage.text();
    const adminNonce = adminPage.headers.get('content-security-policy').match(/nonce-([^']+)/)?.[1];
    assert.equal(adminPage.status, 200);
    assert.ok(adminNonce);
    assert.ok(adminPageHtml.includes(`<script nonce="${adminNonce}">`));
    assert.ok(adminPageHtml.includes(`<style nonce="${adminNonce}">`));
    assert.equal(adminPage.headers.get('cache-control'), 'no-store');

    const unsafeProduct = await fetch(`${baseUrl}/api/products`, {
      method: 'POST',
      headers: { 'Content-Type': 'application/json', Cookie: cookie },
      body: JSON.stringify({ name: 'Unsafe', tag: 'Test', price: 10, image: 'javascript:alert(1)' })
    });
    assert.equal(unsafeProduct.status, 400);

    const insecureImage = await fetch(`${baseUrl}/api/products`, {
      method: 'POST',
      headers: { 'Content-Type': 'application/json', Cookie: cookie },
      body: JSON.stringify({ name: 'Insecure Image', tag: 'Test', price: 10, image: 'http://images.example.test/watch.jpg' })
    });
    assert.equal(insecureImage.status, 400);

    const unsafePaymentUrl = await fetch(`${baseUrl}/api/products`, {
      method: 'POST',
      headers: { 'Content-Type': 'application/json', Cookie: cookie },
      body: JSON.stringify({ name: 'Bad Payment Link', tag: 'Test', price: 10, paymentUrl: 'https://evil.example/pay' })
    });
    assert.equal(unsafePaymentUrl.status, 400);

    const linkedProduct = await fetch(`${baseUrl}/api/products`, {
      method: 'POST',
      headers: { 'Content-Type': 'application/json', Cookie: cookie },
      body: JSON.stringify({
        name: 'Shopier Test',
        tag: 'Test',
        price: 100,
        paymentUrl: 'https://www.shopier.com/ShowProductNew/products.php?id=123'
      })
    });
    assert.equal(linkedProduct.status, 201);
    const linkedProductData = await linkedProduct.json();
    createdProductId = linkedProductData.id;
    assert.equal(linkedProductData.paymentUrl, 'https://www.shopier.com/ShowProductNew/products.php?id=123');

    const outOfStockOrder = await fetch(`${baseUrl}/api/orders`, {
      method: 'POST',
      headers: { 'Content-Type': 'application/json' },
      body: JSON.stringify({
        customerName: 'Test Kullanıcı',
        email: 'test@example.com',
        phone: '05550000000',
        address: 'Test adresi',
        city: 'İstanbul',
        items: [{ id: 1, quantity: 1 }]
      })
    });
    assert.equal(outOfStockOrder.status, 409);

    await new Promise((resolve, reject) => {
      getDb().run('UPDATE products SET stock = 5 WHERE id = 1', (error) => error ? reject(error) : resolve());
    });

    const order = await fetch(`${baseUrl}/api/orders`, {
      method: 'POST',
      headers: { 'Content-Type': 'application/json' },
      body: JSON.stringify({
        customerName: 'Test Kullanıcı',
        email: 'test@example.com',
        phone: '05550000000',
        address: 'Test adresi',
        city: 'İstanbul',
        items: [{ id: 1, quantity: 2, price: 1 }],
        total: 1
      })
    });
    assert.equal(order.status, 201);
    const orderData = await order.json();
    createdOrderId = orderData.id;
    assert.equal(orderData.total, 4998);

    const invalidStatus = await fetch(`${baseUrl}/api/orders/${createdOrderId}`, {
      method: 'PATCH',
      headers: { 'Content-Type': 'application/json', Cookie: cookie },
      body: JSON.stringify({ status: 'unexpected' })
    });
    assert.equal(invalidStatus.status, 400);

    const processing = await fetch(`${baseUrl}/api/orders/${createdOrderId}`, {
      method: 'PATCH',
      headers: { 'Content-Type': 'application/json', Cookie: cookie },
      body: JSON.stringify({ status: 'processing' })
    });
    assert.equal(processing.status, 200);
    const stockAfterReserve = await new Promise((resolve, reject) => {
      getDb().get('SELECT stock FROM products WHERE id = 1', (error, row) => error ? reject(error) : resolve(row.stock));
    });
    assert.equal(stockAfterReserve, 3);

    const cancelled = await fetch(`${baseUrl}/api/orders/${createdOrderId}`, {
      method: 'PATCH',
      headers: { 'Content-Type': 'application/json', Cookie: cookie },
      body: JSON.stringify({ status: 'cancelled' })
    });
    assert.equal(cancelled.status, 200);
    const stockAfterCancel = await new Promise((resolve, reject) => {
      getDb().get('SELECT stock FROM products WHERE id = 1', (error, row) => error ? reject(error) : resolve(row.stock));
    });
    assert.equal(stockAfterCancel, 5);

    const manualOrder = await fetch(`${baseUrl}/api/admin/orders`, {
      method: 'POST',
      headers: { 'Content-Type': 'application/json', Cookie: cookie },
      body: JSON.stringify({
        customerName: 'Shopier Müşterisi',
        email: 'paid@example.com',
        phone: '05550000000',
        address: 'Test adresi',
        city: 'İstanbul',
        productId: 1,
        quantity: 1,
        paymentReference: 'SH-REF-123'
      })
    });
    assert.equal(manualOrder.status, 201);
    const manualOrderData = await manualOrder.json();
    manualOrderId = manualOrderData.id;
    assert.equal(manualOrderData.status, 'processing');
    assert.equal(manualOrderData.payment_source, 'shopier_manual');
    assert.equal(manualOrderData.payment_reference, 'SH-REF-123');

    const paidCancelWithoutRefund = await fetch(`${baseUrl}/api/orders/${manualOrderId}`, {
      method: 'PATCH',
      headers: { 'Content-Type': 'application/json', Cookie: cookie },
      body: JSON.stringify({ status: 'cancelled' })
    });
    assert.equal(paidCancelWithoutRefund.status, 400);

    const paidCancel = await fetch(`${baseUrl}/api/orders/${manualOrderId}`, {
      method: 'PATCH',
      headers: { 'Content-Type': 'application/json', Cookie: cookie },
      body: JSON.stringify({ status: 'cancelled', refundReference: 'RF-REF-321' })
    });
    assert.equal(paidCancel.status, 200);
    assert.equal((await paidCancel.json()).refund_reference, 'RF-REF-321');

    const duplicatePayment = await fetch(`${baseUrl}/api/admin/orders`, {
      method: 'POST',
      headers: { 'Content-Type': 'application/json', Cookie: cookie },
      body: JSON.stringify({
        customerName: 'Shopier Müşterisi',
        email: 'paid@example.com',
        phone: '05550000000',
        address: 'Test adresi',
        city: 'İstanbul',
        productId: 1,
        quantity: 1,
        paymentReference: 'SH-REF-123'
      })
    });
    assert.equal(duplicatePayment.status, 409);

    const shipmentOrder = await fetch(`${baseUrl}/api/orders`, {
      method: 'POST',
      headers: { 'Content-Type': 'application/json' },
      body: JSON.stringify({
        customerName: 'Kargo Testi',
        email: 'shipping@example.com',
        phone: '05550000000',
        address: 'Test adresi',
        city: 'İstanbul',
        items: [{ id: 1, quantity: 1 }]
      })
    });
    assert.equal(shipmentOrder.status, 201);
    shipmentOrderId = (await shipmentOrder.json()).id;

    const shipmentProcessing = await fetch(`${baseUrl}/api/orders/${shipmentOrderId}`, {
      method: 'PATCH',
      headers: { 'Content-Type': 'application/json', Cookie: cookie },
      body: JSON.stringify({ status: 'processing' })
    });
    assert.equal(shipmentProcessing.status, 200);

    const shipped = await fetch(`${baseUrl}/api/orders/${shipmentOrderId}`, {
      method: 'PATCH',
      headers: { 'Content-Type': 'application/json', Cookie: cookie },
      body: JSON.stringify({ status: 'shipped', carrier: 'Test Kargo', trackingNumber: 'TN123' })
    });
    assert.equal(shipped.status, 200);
    const shippedOrder = await shipped.json();
    assert.equal(shippedOrder.tracking_number, 'TN123');

    const shippedCancel = await fetch(`${baseUrl}/api/orders/${shipmentOrderId}`, {
      method: 'PATCH',
      headers: { 'Content-Type': 'application/json', Cookie: cookie },
      body: JSON.stringify({ status: 'cancelled' })
    });
    assert.equal(shippedCancel.status, 409);

    const logout = await fetch(`${baseUrl}/api/logout`, {
      method: 'POST',
      headers: { Cookie: cookie }
    });
    assert.equal(logout.status, 200);
  } finally {
    if (createdProductId) {
      await new Promise((resolve, reject) => {
        getDb().run('DELETE FROM products WHERE id = ?', [createdProductId], (error) => error ? reject(error) : resolve());
      });
    }
    if (createdOrderId) {
      await new Promise((resolve, reject) => {
        getDb().run('DELETE FROM orders WHERE id = ?', [createdOrderId], (error) => error ? reject(error) : resolve());
      });
    }
    if (manualOrderId) {
      await new Promise((resolve, reject) => {
        getDb().run('DELETE FROM orders WHERE id = ?', [manualOrderId], (error) => error ? reject(error) : resolve());
      });
    }
    if (shipmentOrderId) {
      await new Promise((resolve, reject) => {
        getDb().run('DELETE FROM orders WHERE id = ?', [shipmentOrderId], (error) => error ? reject(error) : resolve());
      });
    }
    await new Promise((resolve, reject) => server.close((error) => error ? reject(error) : resolve()));
  }
});
