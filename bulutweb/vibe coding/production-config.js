const minimumAdminPasswordLength = 16;

function validateProductionConfig(env) {
  const issues = [];
  const sessionSecret = env.SESSION_SECRET || '';
  const adminUsername = (env.ADMIN_USERNAME || '').trim();
  const adminPassword = env.ADMIN_PASSWORD || '';
  let validSiteUrl = false;

  try {
    const siteUrl = new URL(env.SITE_URL || '');
    validSiteUrl = siteUrl.protocol === 'https:'
      && !siteUrl.hostname.endsWith('.example')
      && !/^(.+\.)?example\.(com|net|org)$/i.test(siteUrl.hostname)
      && !siteUrl.hostname.includes('your-domain')
      && siteUrl.hostname !== 'localhost';
  } catch {
    validSiteUrl = false;
  }

  if (env.NODE_ENV !== 'production') {
    issues.push('NODE_ENV=production olmalı.');
  }
  if (!validSiteUrl) {
    issues.push('SITE_URL gerçek HTTPS alan adınız olmalı; örnek domain ve localhost kabul edilmez.');
  }
  if (sessionSecret.length < 32 || /replace[-_ ]?with|change[-_ ]?me/i.test(sessionSecret)) {
    issues.push('SESSION_SECRET en az 32 karakterli, rastgele ve örnek değerden farklı olmalı.');
  }
  if (!adminUsername) {
    issues.push('ADMIN_USERNAME belirlenmeli.');
  }
  if (
    adminPassword.length < minimumAdminPasswordLength
    || /replace[-_ ]?with|change[-_ ]?me|admin123|password/i.test(adminPassword)
    || adminPassword.toLowerCase() === adminUsername.toLowerCase()
  ) {
    issues.push(`ADMIN_PASSWORD en az ${minimumAdminPasswordLength} karakterli, kullanıcı adından farklı ve örnek parolalardan biri olmamalı.`);
  }
  if (env.SHOPIER_PAYMENT_MODE !== 'manual-links') {
    issues.push('SHOPIER_PAYMENT_MODE şu an manual-links olmalı; otomatik Shopier ödeme bildirimi bu projede uygulanmış değil.');
  }

  return issues;
}

module.exports = { minimumAdminPasswordLength, validateProductionConfig };
