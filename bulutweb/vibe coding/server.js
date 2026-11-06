require('dotenv').config();

const express = require('express');
const session = require('express-session');
const sqlite3 = require('sqlite3').verbose();
const nodemailer = require('nodemailer');
const crypto = require('node:crypto');
const { promisify } = require('node:util');
const fs = require('fs');
const path = require('path');
const { validateProductionConfig } = require('./production-config');

const app = express();
const PORT = process.env.PORT || 3000;
const projectRoot = __dirname;
const dbPath = process.env.DB_PATH === ':memory:'
  ? ':memory:'
  : path.resolve(projectRoot, process.env.DB_PATH || path.join('data', 'timenest.db'));
const SESSION_SECRET = process.env.SESSION_SECRET || crypto.randomBytes(32).toString('hex');
const scrypt = promisify(crypto.scrypt);
const allowedOrderStatuses = new Set(['pending', 'processing', 'shipped', 'completed', 'cancelled']);
const orderTransitions = {
  pending: new Set(['pending', 'processing', 'cancelled']),
  processing: new Set(['processing', 'shipped', 'completed', 'cancelled']),
  shipped: new Set(['shipped', 'completed']),
  completed: new Set(['completed']),
  cancelled: new Set(['cancelled'])
};
const orderSubmissionAttempts = new Map();
const mailTransporter = process.env.SMTP_HOST
  ? nodemailer.createTransport({
      host: process.env.SMTP_HOST,
      port: Number(process.env.SMTP_PORT || 587),
      secure: process.env.SMTP_SECURE === 'true',
      auth: process.env.SMTP_USER && process.env.SMTP_PASSWORD
        ? { user: process.env.SMTP_USER, pass: process.env.SMTP_PASSWORD }
        : undefined
    })
  : null;

if (process.env.NODE_ENV === 'production') {
  const configIssues = validateProductionConfig(process.env);
  if (configIssues.length) {
    throw new Error(`Production yapılandırması geçersiz:\n- ${configIssues.join('\n- ')}`);
  }
}

if (dbPath !== ':memory:') {
  process.umask(0o077);
  const dbDirectory = path.dirname(dbPath);
  fs.mkdirSync(dbDirectory, { recursive: true, mode: 0o700 });
  fs.chmodSync(dbDirectory, 0o700);
}

const db = new sqlite3.Database(dbPath);
db.configure('busyTimeout', 5000);

class SQLiteSessionStore extends session.Store {
  get(sessionId, callback) {
    db.get('SELECT sess FROM sessions WHERE sid = ? AND expires > ?', [sessionId, Date.now()], (error, row) => {
      if (error) return callback(error);
      if (!row) return callback(null, null);
      try {
        callback(null, JSON.parse(row.sess));
      } catch (parseError) {
        callback(parseError);
      }
    });
  }

  set(sessionId, sessionData, callback = () => {}) {
    const expires = sessionData.cookie?.expires
      ? new Date(sessionData.cookie.expires).getTime()
      : Date.now() + Number(sessionData.cookie?.maxAge || 8 * 60 * 60 * 1000);
    db.run(
      `INSERT INTO sessions (sid, sess, expires) VALUES (?, ?, ?)
       ON CONFLICT(sid) DO UPDATE SET sess = excluded.sess, expires = excluded.expires`,
      [sessionId, JSON.stringify(sessionData), expires],
      callback
    );
  }

  destroy(sessionId, callback = () => {}) {
    db.run('DELETE FROM sessions WHERE sid = ?', [sessionId], callback);
  }

  touch(sessionId, sessionData, callback = () => {}) {
    const expires = sessionData.cookie?.expires
      ? new Date(sessionData.cookie.expires).getTime()
      : Date.now() + Number(sessionData.cookie?.maxAge || 8 * 60 * 60 * 1000);
    db.run('UPDATE sessions SET expires = ? WHERE sid = ?', [expires, sessionId], callback);
  }
}

const seedProducts = [
  {
    name: 'Aero Classic',
    tag: 'Spor',
    badge: 'Yeni',
    rating: 4.8,
    reviews: 223,
    description: 'Hafif ve modern tasarımıyla günlük kullanım için ideal.',
    price: 2499,
    image:
      'https://images.unsplash.com/photo-1523170335258-f5ed11844a49?auto=format&fit=crop&w=900&q=80',
    details: ['Suya dayanıklı yüzey', '7 gün pil ömrü', 'Açık hava kullanımına uygun']
  },
  {
    name: 'Urban Elite',
    tag: 'İş',
    badge: 'Fırsat',
    rating: 4.7,
    reviews: 188,
    description: 'Şık ve profesyonel görünüm sunan zarif bir saat.',
    price: 3299,
    image:
      'https://images.unsplash.com/photo-1542496658-e33a6d0d50f6?auto=format&fit=crop&w=900&q=80',
    details: ['Metal kasa', 'Küçük ekran detayı', 'Ofis ve toplantılara uygun']
  },
  {
    name: 'Night Pulse',
    tag: 'Lüks',
    badge: 'Özel',
    rating: 5,
    reviews: 312,
    description: 'Gece kullanımında dikkat çeken modern bir tasarım.',
    price: 4199,
    image:
      'https://images.unsplash.com/photo-1434056886845-dac89ffe9b56?auto=format&fit=crop&w=900&q=80',
    details: ['Karanlık mod', 'Yüksek kalite kasa', 'Özel etkinliklerde öne çıkar']
  },
  {
    name: 'City Drift',
    tag: 'Günlük',
    badge: 'Popüler',
    rating: 4.9,
    reviews: 154,
    description: 'Her gün kullanıma uygun, hafif ve şık günlük saat.',
    price: 2799,
    image:
      'https://images.unsplash.com/photo-1508057198894-247b23fe5ade?auto=format&fit=crop&w=900&q=80',
    details: ['Kullanımı kolay', 'Premium deri kayış', 'Şık ve minimalist']
  },
  {
    name: 'Summit X',
    tag: 'Spor',
    badge: 'Kampanya',
    rating: 4.6,
    reviews: 134,
    description: 'Koşu ve açık hava aktivite için tasarlanmış dayanıklı model.',
    price: 3599,
    image: 'https://images.unsplash.com/photo-1524592094714-0f0654e20314?auto=format&fit=crop&w=900&q=80',
    details: ['Açık hava dayanımı', 'Parlak ekran', 'Hızlı şarj teknolojisi']
  },
  {
    name: 'Monarch Gold',
    tag: 'Lüks',
    badge: 'Sınıfı',
    rating: 5,
    reviews: 497,
    description: 'Zarif ve gösterişli tasarımıyla özel anlar için ideal saat.',
    price: 5299,
    image: 'https://images.unsplash.com/photo-1517841905240-472988babdf9?auto=format&fit=crop&w=900&q=80',
    details: ['Altın görünüm', 'Premium kasa', 'Özenle seçilmiş malzeme']
  }
];

async function hashPassword(password) {
  const salt = crypto.randomBytes(16).toString('hex');
  const derived = await scrypt(password, salt, 64);
  return `scrypt$${salt}$${derived.toString('hex')}`;
}

async function verifyPassword(password, stored) {
  const [algorithm, salt, hash] = String(stored).split('$');
  if (algorithm !== 'scrypt' || !salt || !hash) return false;
  const expected = Buffer.from(hash, 'hex');
  const actual = await scrypt(password, salt, expected.length);
  return expected.length === actual.length && crypto.timingSafeEqual(expected, actual);
}

function validText(value, maxLength) {
  return typeof value === 'string' && value.trim().length > 0 && value.trim().length <= maxLength;
}

function escapeHTML(value) {
  return String(value).replace(/[&<>"']/g, (character) => ({
    '&': '&amp;',
    '<': '&lt;',
    '>': '&gt;',
    '"': '&quot;',
    "'": '&#39;'
  })[character]);
}

async function sendCustomerEmail(to, subject, text, html) {
  if (!mailTransporter || !to) return false;
  try {
    await mailTransporter.sendMail({
      from: process.env.MAIL_FROM || process.env.SMTP_USER,
      to,
      subject,
      text,
      html
    });
    return true;
  } catch (error) {
    console.error('Customer email delivery failed:', error);
    return false;
  }
}

function validImageUrl(value) {
  if (value === undefined || value === '') return true;
  if (typeof value !== 'string' || value.length > 2048) return false;
  try {
    return new URL(value).protocol === 'https:';
  } catch {
    return false;
  }
}

function validShopierUrl(value) {
  if (value === undefined || value === '') return true;
  if (typeof value !== 'string' || value.length > 2048) return false;
  try {
    const url = new URL(value);
    return url.protocol === 'https:' && (url.hostname === 'shopier.com' || url.hostname.endsWith('.shopier.com'));
  } catch {
    return false;
  }
}

function normalizeProductInput(body) {
  const price = Number(body.price);
  const stock = Number(body.stock ?? 0);
  const details = body.details === undefined ? [] : body.details;
  if (!validText(body.name, 120) || !validText(body.tag, 60)) return null;
  if (!Number.isFinite(price) || price <= 0 || price > 100000000) return null;
  if (body.badge !== undefined && (typeof body.badge !== 'string' || body.badge.length > 60)) return null;
  if (body.description !== undefined && (typeof body.description !== 'string' || body.description.length > 2000)) return null;
  if (!validImageUrl(body.image)) return null;
  if (!validShopierUrl(body.paymentUrl)) return null;
  if (!Number.isSafeInteger(stock) || stock < 0 || stock > 1000000) return null;
  if (!Array.isArray(details) || details.length > 20 || details.some((item) => !validText(item, 200))) return null;

  return {
    name: body.name.trim(),
    tag: body.tag.trim(),
    badge: (body.badge || 'Yeni').trim(),
    description: (body.description || '').trim(),
    price,
    stock,
    image: body.image || 'https://images.unsplash.com/photo-1523170335258-f5ed11844a49?auto=format&fit=crop&w=900&q=80',
    paymentUrl: body.paymentUrl || '',
    details,
    rating: Number.isFinite(Number(body.rating)) ? Math.min(5, Math.max(0, Number(body.rating))) : 4.8,
    reviews: Number.isInteger(Number(body.reviews)) ? Math.max(0, Number(body.reviews)) : 0
  };
}

function run(sql, params = []) {
  return new Promise((resolve, reject) => {
    db.run(sql, params, function onRun(err) {
      if (err) return reject(err);
      resolve({ id: this.lastID, changes: this.changes });
    });
  });
}

function all(sql, params = []) {
  return new Promise((resolve, reject) => {
    db.all(sql, params, (err, rows) => {
      if (err) return reject(err);
      resolve(rows);
    });
  });
}

function get(sql, params = []) {
  return new Promise((resolve, reject) => {
    db.get(sql, params, (err, row) => {
      if (err) return reject(err);
      resolve(row);
    });
  });
}

async function initDatabase() {
  await run(`
    CREATE TABLE IF NOT EXISTS products (
      id INTEGER PRIMARY KEY AUTOINCREMENT,
      name TEXT NOT NULL,
      tag TEXT NOT NULL,
      badge TEXT,
      rating REAL DEFAULT 0,
      reviews INTEGER DEFAULT 0,
      description TEXT,
      price REAL NOT NULL,
      image TEXT,
      details TEXT DEFAULT '[]',
      created_at TEXT DEFAULT CURRENT_TIMESTAMP
    )
  `);

  const productColumns = await all('PRAGMA table_info(products)');
  if (!productColumns.some((column) => column.name === 'payment_url')) {
    await run("ALTER TABLE products ADD COLUMN payment_url TEXT NOT NULL DEFAULT ''");
  }
  if (!productColumns.some((column) => column.name === 'stock')) {
    await run('ALTER TABLE products ADD COLUMN stock INTEGER NOT NULL DEFAULT 0');
  }

  await run(`
    CREATE TABLE IF NOT EXISTS orders (
      id INTEGER PRIMARY KEY AUTOINCREMENT,
      customer_name TEXT NOT NULL,
      email TEXT,
      phone TEXT,
      address TEXT,
      total REAL NOT NULL,
      status TEXT DEFAULT 'pending',
      items TEXT NOT NULL,
      created_at TEXT DEFAULT CURRENT_TIMESTAMP
    )
  `);
  await run('CREATE INDEX IF NOT EXISTS orders_created_at_idx ON orders(created_at DESC)');

  const orderColumns = await all('PRAGMA table_info(orders)');
  if (!orderColumns.some((column) => column.name === 'stock_reserved')) {
    await run('ALTER TABLE orders ADD COLUMN stock_reserved INTEGER NOT NULL DEFAULT 0');
  }
  if (!orderColumns.some((column) => column.name === 'carrier')) {
    await run("ALTER TABLE orders ADD COLUMN carrier TEXT NOT NULL DEFAULT ''");
  }
  if (!orderColumns.some((column) => column.name === 'tracking_number')) {
    await run("ALTER TABLE orders ADD COLUMN tracking_number TEXT NOT NULL DEFAULT ''");
  }
  if (!orderColumns.some((column) => column.name === 'payment_reference')) {
    await run("ALTER TABLE orders ADD COLUMN payment_reference TEXT NOT NULL DEFAULT ''");
  }
  if (!orderColumns.some((column) => column.name === 'payment_source')) {
    await run("ALTER TABLE orders ADD COLUMN payment_source TEXT NOT NULL DEFAULT 'demo'");
  }
  if (!orderColumns.some((column) => column.name === 'refund_reference')) {
    await run("ALTER TABLE orders ADD COLUMN refund_reference TEXT NOT NULL DEFAULT ''");
  }
  await run("CREATE UNIQUE INDEX IF NOT EXISTS orders_shopier_reference_unique ON orders(payment_reference) WHERE payment_source = 'shopier_manual'");

  await run(`
    CREATE TABLE IF NOT EXISTS admin_users (
      id INTEGER PRIMARY KEY AUTOINCREMENT,
      username TEXT UNIQUE NOT NULL,
      password TEXT NOT NULL,
      role TEXT DEFAULT 'admin',
      created_at TEXT DEFAULT CURRENT_TIMESTAMP
    )
  `);

  await run(`
    CREATE TABLE IF NOT EXISTS sessions (
      sid TEXT PRIMARY KEY,
      sess TEXT NOT NULL,
      expires INTEGER NOT NULL
    )
  `);
  await run('CREATE INDEX IF NOT EXISTS sessions_expires_idx ON sessions(expires)');
  await run('DELETE FROM sessions WHERE expires <= ?', [Date.now()]);

  const adminUsers = await all('SELECT id, username, password FROM admin_users');
  if (adminUsers.length === 0) {
    const username = process.env.ADMIN_USERNAME || 'admin';
    const password = process.env.ADMIN_PASSWORD || crypto.randomBytes(18).toString('base64url');
    await run('INSERT INTO admin_users (username, password, role) VALUES (?, ?, ?)', [username, await hashPassword(password), 'admin']);
    if (process.env.NODE_ENV !== 'production') {
      if (!process.env.ADMIN_PASSWORD) console.warn(`İlk admin parolası (yalnızca bu kez): ${username} / ${password}`);
    }
  } else {
    for (const adminUser of adminUsers) {
      if (!String(adminUser.password).startsWith('scrypt$')) {
        const rotateDefault = !process.env.ADMIN_PASSWORD && adminUser.password === 'admin123';
        const password = rotateDefault ? crypto.randomBytes(18).toString('base64url') : adminUser.password;
        await run('UPDATE admin_users SET password = ? WHERE id = ?', [await hashPassword(password), adminUser.id]);
        if (rotateDefault) console.warn(`Varsayılan admin parolası yenilendi (yalnızca bu kez): ${adminUser.username} / ${password}`);
      } else if (!process.env.ADMIN_PASSWORD && adminUser.username === 'admin' && await verifyPassword('admin123', adminUser.password)) {
        const password = crypto.randomBytes(18).toString('base64url');
        await run('UPDATE admin_users SET password = ? WHERE id = ?', [await hashPassword(password), adminUser.id]);
        console.warn(`Varsayılan admin parolası yenilendi (yalnızca bu kez): ${adminUser.username} / ${password}`);
      }
    }
    if (process.env.ADMIN_USERNAME && process.env.ADMIN_PASSWORD) {
      const configuredAdmin = adminUsers[0];
      await run('UPDATE admin_users SET username = ?, password = ? WHERE id = ?', [
        process.env.ADMIN_USERNAME,
        await hashPassword(process.env.ADMIN_PASSWORD),
        configuredAdmin.id
      ]);
    }
  }

  const countRow = await get('SELECT COUNT(*) AS count FROM products');
  if (Number(countRow.count) === 0) {
    for (const product of seedProducts) {
      await run(
        `INSERT INTO products (name, tag, badge, rating, reviews, description, price, image, details, payment_url, stock)
         VALUES (?, ?, ?, ?, ?, ?, ?, ?, ?, ?, ?)`,
        [
          product.name,
          product.tag,
          product.badge,
          product.rating,
          product.reviews,
          product.description,
          product.price,
          product.image,
          JSON.stringify(product.details),
          '',
          0
        ]
      );
    }
  } else {
    for (const product of seedProducts) {
      const existing = await get('SELECT id FROM products WHERE name = ?', [product.name]);
      if (!existing) {
        await run(
          `INSERT INTO products (name, tag, badge, rating, reviews, description, price, image, details, payment_url, stock)
           VALUES (?, ?, ?, ?, ?, ?, ?, ?, ?, ?, ?)`,
          [product.name, product.tag, product.badge, product.rating, product.reviews, product.description, product.price, product.image, JSON.stringify(product.details), '', 0]
        );
      }
    }
  }

  if (process.env.NODE_ENV === 'production' && dbPath !== ':memory:' && fs.existsSync(dbPath)) {
    fs.chmodSync(dbPath, 0o600);
  }

  return db;
}

function getDb() {
  return db;
}

function requireAdmin(req, res, next) {
  if (!req.session || !req.session.user) {
    return res.status(401).json({ message: 'Yetkisiz erişim.' });
  }

  next();
}

if (process.env.NODE_ENV === 'production') app.set('trust proxy', 1);
app.use((req, res, next) => {
  const nonce = crypto.randomBytes(18).toString('base64');
  res.locals.cspNonce = nonce;
  res.setHeader('X-Content-Type-Options', 'nosniff');
  res.setHeader('X-Frame-Options', 'DENY');
  res.setHeader('Referrer-Policy', 'strict-origin-when-cross-origin');
  res.setHeader('Permissions-Policy', 'camera=(), microphone=(), geolocation=()');
  res.setHeader(
    'Content-Security-Policy',
    [
      "default-src 'self'",
      "base-uri 'self'",
      "object-src 'none'",
      "frame-ancestors 'none'",
      "form-action 'self' https://shopier.com https://*.shopier.com",
      `script-src 'self' 'nonce-${nonce}'`,
      `style-src 'self' 'nonce-${nonce}' https://fonts.googleapis.com`,
      "font-src 'self' https://fonts.gstatic.com",
      "img-src 'self' data: https:",
      "connect-src 'self'",
      ...(process.env.NODE_ENV === 'production' ? ['upgrade-insecure-requests'] : [])
    ].join('; ')
  );
  if (req.path.startsWith('/api/')) {
    res.setHeader('Cache-Control', 'no-store');
  }
  if (process.env.NODE_ENV === 'production') {
    res.setHeader('Strict-Transport-Security', 'max-age=31536000; includeSubDomains');
  }

  if (req.method !== 'GET' && req.method !== 'HEAD') {
    const origin = req.get('origin');
    if (origin && origin !== `${req.protocol}://${req.get('host')}`) {
      return res.status(403).json({ message: 'İstek kaynağı doğrulanamadı.' });
    }
    if (req.get('sec-fetch-site') === 'cross-site') {
      return res.status(403).json({ message: 'Çapraz site isteğine izin verilmiyor.' });
    }
  }

  next();
});
app.use(express.json({ limit: '64kb' }));
app.use(['/data', '/tests', '/node_modules', '/scripts'], (req, res) => {
  res.status(404).json({ message: 'Sayfa bulunamadı.' });
});
app.use(['/admin.html', '/server.js', '/production-config.js', '/package.json', '/package-lock.json', '/README.md', '/.env.example'], (req, res) => {
  res.status(404).json({ message: 'Sayfa bulunamadı.' });
});
app.use(
  session({
    secret: SESSION_SECRET,
    name: 'timenest.sid',
    store: new SQLiteSessionStore(),
    resave: false,
    saveUninitialized: false,
    cookie: {
      httpOnly: true,
      sameSite: 'lax',
      secure: process.env.NODE_ENV === 'production',
      maxAge: 1000 * 60 * 60 * 8
    }
  })
);
app.use(express.static(projectRoot));

app.use('/api/orders', (req, res, next) => {
  if (req.method !== 'POST') return next();
  const now = Date.now();
  const attempt = orderSubmissionAttempts.get(req.ip);
  if (!attempt || attempt.resetAt <= now) {
    orderSubmissionAttempts.set(req.ip, { count: 1, resetAt: now + 15 * 60 * 1000 });
    return next();
  }
  if (attempt.count >= 10) {
    return res.status(429).json({ message: 'Çok fazla sipariş denemesi. Daha sonra tekrar deneyin.' });
  }
  attempt.count += 1;
  next();
});

async function sendHtmlPage(res, fileName) {
  try {
    const page = await fs.promises.readFile(path.join(projectRoot, fileName), 'utf8');
    res.setHeader('Cache-Control', 'no-store');
    res.type('html').send(page.replaceAll('__CSP_NONCE__', res.locals.cspNonce));
  } catch (error) {
    console.error(`Page delivery failed (${fileName}):`, error);
    res.status(500).send('Sayfa şu anda yüklenemiyor.');
  }
}

app.get('/login', (req, res) => {
  sendHtmlPage(res, 'login.html');
});

app.get('/admin', (req, res) => {
  if (!req.session.user) {
    return res.redirect('/login');
  }

  sendHtmlPage(res, 'admin.html');
});

app.get('/api/session', (req, res) => {
  res.json({
    authenticated: !!req.session.user,
    user: req.session.user || null
  });
});

const loginAttempts = new Map();
app.use('/api/login', (req, res, next) => {
  const now = Date.now();
  const ip = req.ip;
  const attempt = loginAttempts.get(ip);
  if (attempt && attempt.resetAt <= now) loginAttempts.delete(ip);
  const current = loginAttempts.get(ip);
  if (current && current.count >= 5) {
    return res.status(429).json({ message: 'Çok fazla giriş denemesi. 15 dakika sonra tekrar deneyin.' });
  }
  res.on('finish', () => {
    if (res.statusCode === 401) {
      const currentAttempt = loginAttempts.get(ip);
      loginAttempts.set(ip, {
        count: (currentAttempt?.count || 0) + 1,
        resetAt: currentAttempt?.resetAt || now + 15 * 60 * 1000
      });
    } else if (res.statusCode === 200) {
      loginAttempts.delete(ip);
    }
  });
  next();
});

app.post('/api/login', async (req, res) => {
  const { username, password } = req.body;

  if (!validText(username, 120) || typeof password !== 'string' || password.length > 200) {
    return res.status(400).json({ message: 'Kullanıcı adı ve şifre zorunludur.' });
  }

  const user = await get('SELECT * FROM admin_users WHERE username = ?', [username.trim()]);

  if (!user || !(await verifyPassword(password, user.password))) {
    return res.status(401).json({ message: 'Geçersiz kullanıcı adı veya şifre.' });
  }

  req.session.regenerate((error) => {
    if (error) return res.status(500).json({ message: 'Oturum başlatılamadı.' });
    req.session.user = { username: user.username, role: user.role };
    req.session.save((saveError) => {
      if (saveError) return res.status(500).json({ message: 'Oturum kaydedilemedi.' });
      res.json({ ok: true, user: req.session.user });
    });
  });
});

app.post('/api/logout', (req, res) => {
  req.session.destroy(() => {
    res.json({ ok: true });
  });
});

app.get('/api/health', (req, res) => {
  res.json({ ok: true, message: 'TimeNest API is online' });
});

app.get('/api/store-config', (req, res) => {
  res.json({ demoCheckoutEnabled: process.env.NODE_ENV !== 'production' });
});

app.get('/api/products', async (req, res) => {
  try {
    const rows = await all('SELECT * FROM products ORDER BY id DESC');
    const normalized = rows.map((row) => ({
      ...row,
      paymentUrl: row.payment_url || '',
      details: JSON.parse(row.details || '[]')
    }));
    res.json(normalized);
  } catch (error) {
    console.error('Product list failed:', error);
    res.status(500).json({ message: 'Ürünler yüklenemedi.' });
  }
});

app.post('/api/products', requireAdmin, async (req, res) => {
  try {
    const product = normalizeProductInput(req.body);
    if (!product) return res.status(400).json({ message: 'Ürün bilgileri geçersiz.' });

    const result = await run(
      `INSERT INTO products (name, tag, badge, rating, reviews, description, price, image, details, payment_url, stock)
       VALUES (?, ?, ?, ?, ?, ?, ?, ?, ?, ?, ?)`,
      [
        product.name,
        product.tag,
        product.badge,
        product.rating,
        product.reviews,
        product.description,
        product.price,
        product.image,
        JSON.stringify(product.details),
        product.paymentUrl,
        product.stock
      ]
    );

    const savedProduct = await get('SELECT * FROM products WHERE id = ?', [result.id]);
    res.status(201).json({
      ...savedProduct,
      paymentUrl: savedProduct.payment_url || '',
      details: JSON.parse(savedProduct.details || '[]')
    });
  } catch (error) {
    console.error('Product creation failed:', error);
    res.status(500).json({ message: 'Ürün kaydedilemedi.' });
  }
});

app.put('/api/products/:id', requireAdmin, async (req, res) => {
  try {
    const productId = Number(req.params.id);
    const product = normalizeProductInput(req.body);
    if (!Number.isSafeInteger(productId) || productId < 1) return res.status(400).json({ message: 'Ürün numarası geçersiz.' });
    if (!product) return res.status(400).json({ message: 'Ürün bilgileri geçersiz.' });

    await run(
      `UPDATE products
      SET name = ?, tag = ?, badge = ?, rating = ?, reviews = ?, description = ?, price = ?, image = ?, details = ?, payment_url = ?, stock = ?
       WHERE id = ?`,
      [
        product.name,
        product.tag,
        product.badge,
        product.rating,
        product.reviews,
        product.description,
        product.price,
        product.image,
        JSON.stringify(product.details),
        product.paymentUrl,
        product.stock,
        productId
      ]
    );

    const updated = await get('SELECT * FROM products WHERE id = ?', [productId]);
    if (!updated) return res.status(404).json({ message: 'Ürün bulunamadı.' });
    res.json({
      ...updated,
      paymentUrl: updated.payment_url || '',
      details: JSON.parse(updated.details || '[]')
    });
  } catch (error) {
    console.error('Product update failed:', error);
    res.status(500).json({ message: 'Ürün güncellenemedi.' });
  }
});

app.delete('/api/products/:id', requireAdmin, async (req, res) => {
  try {
    const productId = Number(req.params.id);
    if (!Number.isSafeInteger(productId) || productId < 1) return res.status(400).json({ message: 'Ürün numarası geçersiz.' });
    const result = await run('DELETE FROM products WHERE id = ?', [productId]);
    if (!result.changes) return res.status(404).json({ message: 'Ürün bulunamadı.' });
    res.json({ success: true, id: productId });
  } catch (error) {
    console.error('Product deletion failed:', error);
    res.status(500).json({ message: 'Ürün silinemedi.' });
  }
});

app.get('/api/orders', requireAdmin, async (req, res) => {
  try {
    const rows = await all('SELECT * FROM orders ORDER BY created_at DESC');
    const normalized = rows.map((row) => ({
      ...row,
      items: JSON.parse(row.items || '[]')
    }));
    res.json(normalized);
  } catch (error) {
    console.error('Order list failed:', error);
    res.status(500).json({ message: 'Siparişler yüklenemedi.' });
  }
});

app.patch('/api/orders/:id', requireAdmin, async (req, res) => {
  try {
    const { status, carrier = '', trackingNumber = '', refundReference = '' } = req.body;
    const orderId = Number(req.params.id);

    if (!Number.isSafeInteger(orderId) || orderId < 1 || !allowedOrderStatuses.has(status)
      || typeof carrier !== 'string' || carrier.length > 80
      || typeof trackingNumber !== 'string' || trackingNumber.length > 120
      || typeof refundReference !== 'string' || refundReference.length > 120) {
      return res.status(400).json({ message: 'Sipariş numarası veya durumu geçersiz.' });
    }
    if (status === 'shipped' && (!carrier.trim() || !trackingNumber.trim())) {
      return res.status(400).json({ message: 'Kargoya verildi durumu için kargo firması ve takip numarası zorunludur.' });
    }

    const currentOrder = await get('SELECT * FROM orders WHERE id = ?', [orderId]);
    if (!currentOrder) return res.status(404).json({ message: 'Sipariş bulunamadı.' });
    if (status === 'cancelled' && currentOrder.payment_source === 'shopier_manual' && !validText(refundReference, 120)) {
      return res.status(400).json({ message: 'Ödenmiş Shopier siparişini iptal etmek için önce iade yapıp iade referansını girin.' });
    }
    if (!orderTransitions[currentOrder.status]?.has(status)) {
      return res.status(409).json({ message: 'Bu sipariş durumu geçişine izin verilmiyor.' });
    }

    const orderItems = JSON.parse(currentOrder.items || '[]');
    const changedStock = [];
    const shouldReserveStock = ['processing', 'shipped', 'completed'].includes(status);
    if (shouldReserveStock && !currentOrder.stock_reserved) {
      for (const item of orderItems) {
        const result = await run('UPDATE products SET stock = stock - ? WHERE id = ? AND stock >= ?', [item.quantity, item.id, item.quantity]);
        if (!result.changes) {
          for (const reservedItem of changedStock) {
            await run('UPDATE products SET stock = stock + ? WHERE id = ?', [reservedItem.quantity, reservedItem.id]);
          }
          return res.status(409).json({ message: 'Yetersiz stok. Sipariş işleme alınmadı.' });
        }
        changedStock.push(item);
      }
    }

    if (status === 'cancelled' && currentOrder.stock_reserved) {
      for (const item of orderItems) {
        await run('UPDATE products SET stock = stock + ? WHERE id = ?', [item.quantity, item.id]);
      }
    }

    const stockReserved = status === 'cancelled' ? 0 : (currentOrder.stock_reserved || shouldReserveStock ? 1 : 0);
    await run('UPDATE orders SET status = ?, stock_reserved = ?, carrier = ?, tracking_number = ?, refund_reference = ? WHERE id = ?', [
      status,
      stockReserved,
      carrier.trim(),
      trackingNumber.trim(),
      refundReference.trim(),
      orderId
    ]);
    const updated = await get('SELECT * FROM orders WHERE id = ?', [orderId]);

    if (updated.email && (updated.status !== currentOrder.status || updated.tracking_number !== currentOrder.tracking_number)) {
      const detail = updated.tracking_number
        ? `Kargo: ${updated.carrier || 'Belirtilmedi'}\nTakip numarası: ${updated.tracking_number}`
        : `Yeni sipariş durumunuz: ${updated.status}`;
      await sendCustomerEmail(
        updated.email,
        `TimeNest sipariş #${updated.id} güncellendi`,
        `Merhaba ${updated.customer_name},\n\n${detail}`,
        `<p>Merhaba ${escapeHTML(updated.customer_name)},</p><p>${escapeHTML(detail).replace(/\n/g, '<br>')}</p>`
      );
    }

    res.json({
      ...updated,
      items: JSON.parse(updated.items || '[]')
    });
  } catch (error) {
    console.error('Order status update failed:', error);
    res.status(500).json({ message: 'Sipariş durumu güncellenemedi.' });
  }
});

app.post('/api/orders', async (req, res) => {
  if (process.env.NODE_ENV === 'production') {
    return res.status(410).json({
      message: 'Deneme siparişi canlı mağazada kapalıdır. Ödeme bağlantısı bulunan ürünleri Shopier üzerinden satın alabilirsiniz.'
    });
  }

  try {
    const { customerName, email, phone, address, city, items, coupon } = req.body;
    if (!validText(customerName, 120) || !validText(email, 254) || !/^[^\s@]+@[^\s@]+\.[^\s@]+$/.test(email) || !validText(phone, 40) || !validText(address, 1000) || !validText(city, 100)) {
      return res.status(400).json({ message: 'Müşteri bilgileri geçersiz.' });
    }
    if (!Array.isArray(items) || !items.length || items.length > 20) {
      return res.status(400).json({ message: 'Müşteri bilgileri ve ürün listesi gereklidir.' });
    }

    let subtotal = 0;
    const verifiedItems = [];
    for (const item of items) {
      if (!Number.isSafeInteger(item?.id) || item.id < 1 || !Number.isSafeInteger(item?.quantity) || item.quantity < 1 || item.quantity > 20) {
        return res.status(400).json({ message: 'Sepet içeriği geçersiz.' });
      }
      const product = await get('SELECT id, name, price, stock FROM products WHERE id = ?', [item.id]);
      if (!product) return res.status(400).json({ message: 'Sepette bulunmayan bir ürün var.' });
      if (Number(product.stock) < item.quantity) return res.status(409).json({ message: `${product.name} için yeterli stok bulunmuyor.` });
      subtotal += Number(product.price) * item.quantity;
      verifiedItems.push({ id: product.id, name: product.name, price: Number(product.price), quantity: item.quantity });
    }
    const discountRate = coupon === 'TIME10' ? 0.1 : coupon === 'WATCH15' ? 0.15 : 0;
    const total = Math.round(subtotal * (1 - discountRate));
    const fullAddress = `${address.trim()}, ${city.trim()}`;

    const result = await run(
      `INSERT INTO orders (customer_name, email, phone, address, total, status, items)
       VALUES (?, ?, ?, ?, ?, ?, ?)`,
      [
        customerName,
        email.trim(),
        phone || '',
        fullAddress,
        total,
        'pending',
        JSON.stringify(verifiedItems)
      ]
    );

    const savedOrder = await get('SELECT * FROM orders WHERE id = ?', [result.id]);
    const summary = verifiedItems.map((item) => `${item.name} x ${item.quantity}`).join(', ');
    await sendCustomerEmail(
      savedOrder.email,
      `TimeNest deneme siparişi #${savedOrder.id}`,
      `Merhaba ${savedOrder.customer_name},\nDeneme siparişiniz kaydedildi. Ödeme alınmadı.\nÜrünler: ${summary}\nToplam: ₺${savedOrder.total}`,
      `<p>Merhaba ${escapeHTML(savedOrder.customer_name)},</p><p>Deneme siparişiniz kaydedildi. Ödeme alınmadı.</p><p>${escapeHTML(summary)}</p><p>Toplam: ₺${savedOrder.total}</p>`
    );
    res.status(201).json({
      ...savedOrder,
      items: JSON.parse(savedOrder.items || '[]')
    });
  } catch (error) {
    console.error('Order creation failed:', error);
    res.status(500).json({ message: 'Sipariş kaydedilemedi.' });
  }
});

app.post('/api/admin/orders', requireAdmin, async (req, res) => {
  let reservedProduct;
  let reservedQuantity = 0;
  try {
    const { customerName, email, phone, address, city, productId, quantity, paymentReference } = req.body;
    const parsedProductId = Number(productId);
    const parsedQuantity = Number(quantity);
    if (!validText(customerName, 120) || !validText(email, 254)
      || !/^[^\s@]+@[^\s@]+\.[^\s@]+$/.test(email)
      || !validText(phone, 40) || !validText(address, 1000) || !validText(city, 100)
      || !Number.isSafeInteger(parsedProductId) || parsedProductId < 1
      || !Number.isSafeInteger(parsedQuantity) || parsedQuantity < 1 || parsedQuantity > 20
      || !validText(paymentReference, 120)) {
      return res.status(400).json({ message: 'Müşteri, ürün, adet ve Shopier ödeme referansı bilgilerini kontrol edin.' });
    }

    const product = await get('SELECT id, name, price FROM products WHERE id = ?', [parsedProductId]);
    if (!product) return res.status(404).json({ message: 'Ürün bulunamadı.' });
    const existingPayment = await get(
      "SELECT id FROM orders WHERE payment_source = 'shopier_manual' AND payment_reference = ?",
      [paymentReference.trim()]
    );
    if (existingPayment) return res.status(409).json({ message: 'Bu Shopier ödeme referansı daha önce kaydedilmiş.' });

    const reservation = await run(
      'UPDATE products SET stock = stock - ? WHERE id = ? AND stock >= ?',
      [parsedQuantity, parsedProductId, parsedQuantity]
    );
    if (!reservation.changes) return res.status(409).json({ message: 'Yetersiz stok; ödenmiş siparişi kaydetmeden stoğu kontrol edin.' });
    reservedProduct = product;
    reservedQuantity = parsedQuantity;

    const total = Number(product.price) * parsedQuantity;
    const fullAddress = `${address.trim()}, ${city.trim()}`;
    const result = await run(
      `INSERT INTO orders (customer_name, email, phone, address, total, status, items, stock_reserved, payment_reference, payment_source)
       VALUES (?, ?, ?, ?, ?, 'processing', ?, 1, ?, 'shopier_manual')`,
      [
        customerName.trim(),
        email.trim(),
        phone.trim(),
        fullAddress,
        total,
        JSON.stringify([{ id: product.id, name: product.name, price: Number(product.price), quantity: parsedQuantity }]),
        paymentReference.trim()
      ]
    );

    const savedOrder = await get('SELECT * FROM orders WHERE id = ?', [result.id]);
    reservedProduct = null;
    await sendCustomerEmail(
      savedOrder.email,
      `TimeNest siparişiniz alındı #${savedOrder.id}`,
      `Merhaba ${savedOrder.customer_name},\nShopier ödemeniz mağaza tarafından doğrulandı ve siparişiniz işleme alındı.\nÖdeme referansı: ${savedOrder.payment_reference}\nToplam: ₺${savedOrder.total}`,
      `<p>Merhaba ${escapeHTML(savedOrder.customer_name)},</p><p>Shopier ödemeniz mağaza tarafından doğrulandı ve siparişiniz işleme alındı.</p><p>Ödeme referansı: ${escapeHTML(savedOrder.payment_reference)}</p><p>Toplam: ₺${savedOrder.total}</p>`
    );
    res.status(201).json({ ...savedOrder, items: JSON.parse(savedOrder.items || '[]') });
  } catch (error) {
    if (reservedProduct && reservedQuantity) {
      await run('UPDATE products SET stock = stock + ? WHERE id = ?', [reservedQuantity, reservedProduct.id]);
    }
    if (error.code === 'SQLITE_CONSTRAINT') {
      return res.status(409).json({ message: 'Bu Shopier ödeme referansı daha önce kaydedilmiş.' });
    }
    console.error('Manual paid order creation failed:', error);
    res.status(500).json({ message: 'Ödenmiş sipariş kaydedilemedi.' });
  }
});

app.use((req, res) => {
  res.status(404).json({ message: 'Sayfa bulunamadı.' });
});

if (require.main === module) {
  (async () => {
    await initDatabase();
    if (dbPath !== ':memory:' && fs.existsSync(dbPath)) fs.chmodSync(dbPath, 0o600);

    app.listen(PORT, () => {
      console.log(`TimeNest API is running on http://localhost:${PORT}`);
    });
  })();
}

module.exports = {
  initDatabase,
  getDb,
  app
};
