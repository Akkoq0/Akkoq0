require('dotenv').config();

const sqlite3 = require('sqlite3').verbose();
const fs = require('node:fs');
const path = require('node:path');
const { validateProductionConfig } = require('../production-config');

const projectRoot = path.join(__dirname, '..');
const databasePath = process.env.DB_PATH === ':memory:'
  ? ':memory:'
  : path.resolve(projectRoot, process.env.DB_PATH || path.join('data', 'timenest.db'));
const blockers = [];
const warnings = [];

function requireSetting(name, valid, message) {
  if (!valid) blockers.push(message || `${name} ayarlanmalı.`);
}

const [nodeMajor, nodeMinor] = process.versions.node.split('.').map(Number);
requireSetting(
  'Node.js',
  nodeMajor > 20 || (nodeMajor === 20 && nodeMinor >= 17),
  'Node.js 20.17.0 veya üzeri olmalı.'
);

blockers.push(...validateProductionConfig(process.env));
requireSetting('SUPPORT_EMAIL', /^[^\s@]+@[^\s@]+\.[^\s@]+$/.test(process.env.SUPPORT_EMAIL || ''), 'SUPPORT_EMAIL gerçek müşteri destek adresi olmalı.');
requireSetting('SMTP', Boolean(process.env.SMTP_HOST && process.env.SMTP_USER && process.env.SMTP_PASSWORD && process.env.MAIL_FROM), 'SMTP_HOST, SMTP_USER, SMTP_PASSWORD ve MAIL_FROM tamamlanmalı.');

const envPath = path.join(projectRoot, '.env');
if (fs.existsSync(envPath) && (fs.statSync(envPath).mode & 0o077) !== 0) {
  blockers.push('.env dosya izni yalnızca sahibi okuyup yazacak şekilde 0600 olmalı.');
}

const legalPage = fs.readFileSync(path.join(projectRoot, 'legal.html'), 'utf8');
const legalPlaceholders = legalPage.match(/\[[^\]]+\]/g) || [];
requireSetting('LEGAL_REVIEWED', process.env.LEGAL_REVIEWED === 'true' && legalPlaceholders.length === 0, 'legal.html işletme bilgileriyle doldurulmalı, köşeli parantezler kaldırılmalı ve hukuk uzmanı incelemesinden sonra LEGAL_REVIEWED=true yapılmalı.');

if (process.env.SHOPIER_PAYMENT_MODE === 'manual-links') {
  warnings.push('Shopier tahsilatı otomatik olarak site siparişleriyle eşleşmez; her ödeme Shopier panelinden elle doğrulanmalı.');
}

if (!fs.existsSync(databasePath)) {
  blockers.push(`SQLite veritabanı bulunamadı: ${databasePath}. Sunucuyu bir kez başlatıp seed ürünlerini oluşturun.`);
} else {
  const database = new sqlite3.Database(databasePath, sqlite3.OPEN_READONLY, (openError) => {
    if (openError) {
      blockers.push(`SQLite veritabanı açılamadı: ${openError.message}`);
      finish();
      return;
    }

    database.all('SELECT name, price, stock, payment_url FROM products ORDER BY name', (queryError, products) => {
      if (queryError) {
        blockers.push(`Ürün tablosu okunamadı: ${queryError.message}`);
      } else if (!products.length) {
        blockers.push('Veritabanında ürün yok.');
      } else {
        const availableProducts = products.filter((product) => Number(product.stock) > 0);
        if (!availableProducts.length) blockers.push('Stokta satışa açık ürün yok; admin panelinden gerçek stok adetlerini girin.');

        for (const product of availableProducts) {
          let validPaymentUrl = false;
          try {
            const paymentUrl = new URL(product.payment_url);
            validPaymentUrl = paymentUrl.protocol === 'https:'
              && (paymentUrl.hostname === 'shopier.com' || paymentUrl.hostname.endsWith('.shopier.com'));
          } catch {
            validPaymentUrl = false;
          }
          if (!validPaymentUrl) blockers.push(`${product.name}: stok var ama geçerli Shopier HTTPS ürün bağlantısı yok.`);
          if (!Number.isFinite(Number(product.price)) || Number(product.price) <= 0) blockers.push(`${product.name}: fiyat geçersiz.`);
        }

        const unavailableCount = products.length - availableProducts.length;
        if (unavailableCount) warnings.push(`${unavailableCount} ürün stok 0 olduğu için mağazada satın alınamaz.`);
      }

      const databasePermissions = fs.statSync(databasePath).mode & 0o777;
      if ((databasePermissions & 0o077) !== 0) blockers.push('SQLite veritabanı dosya izni 0600 olmalı; müşteri bilgileri içerir.');
      database.close(finish);
    });
  });
}

function finish() {
  console.log('\nTimeNest yayın ön-kontrolü');
  console.log(`Engel: ${blockers.length} · Uyarı: ${warnings.length}`);
  for (const blocker of blockers) console.log(`BLOCKER: ${blocker}`);
  for (const warning of warnings) console.log(`UYARI: ${warning}`);
  if (!blockers.length) console.log('Teknik kontrol tamam. Gerçek ödeme ve sözleşme gereksinimlerini sağlayıcılarla ayrıca doğrulayın.');
  process.exitCode = blockers.length ? 1 : 0;
}