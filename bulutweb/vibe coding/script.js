let products = [];
let catalogLoadError = false;
const productIcons = {
  'Aero Classic': '⌚',
  'Urban Elite': '⏱️',
  'Night Pulse': '🌙',
  'City Drift': '🕰️',
  'Summit X': '🏃',
  'Monarch Gold': '👑'
};

const cartStorageKey = 'timenest-cart';
const favoriteStorageKey = 'timenest-favorites';
const couponStorageKey = 'timenest-coupon';
const productGrid = document.getElementById('productGrid');
const cartCount = document.getElementById('cartCount');
const toast = document.getElementById('toast');
const hourHand = document.getElementById('hourHand');
const minuteHand = document.getElementById('minuteHand');
const secondHand = document.getElementById('secondHand');
const watchFace = document.getElementById('watchFace');
const watchTimeLabel = document.getElementById('watchTimeLabel');
const detailName = document.getElementById('detailName');
const detailPrice = document.getElementById('detailPrice');
const detailTag = document.getElementById('detailTag');
const detailDescription = document.getElementById('detailDescription');
const detailIcon = document.getElementById('detailIcon');
const detailFeatures = document.getElementById('detailFeatures');
const detailAddToCart = document.getElementById('detailAddToCart');
const detailFavorite = document.getElementById('detailFavorite');
const detailPaymentLink = document.getElementById('detailPaymentLink');
const cartItems = document.getElementById('cartItems');
const cartTotal = document.getElementById('cartTotal');
const cartTotalFinal = document.getElementById('cartTotalFinal');
const discountValue = document.getElementById('discountValue');
const checkoutForm = document.getElementById('checkoutForm');
const searchInput = document.getElementById('searchInput');
const filterButtons = document.querySelectorAll('.filter-btn');
const categoryButtons = document.querySelectorAll('[data-filter-category]');
const priceFilterButtons = document.querySelectorAll('.price-filter-btn');
const catalogCount = document.getElementById('catalogCount');
const mobileNavToggle = document.querySelector('[data-mobile-nav-toggle]');
const siteMenu = document.getElementById('siteMenu');
const couponInput = document.getElementById('couponInput');
const couponButton = document.getElementById('applyCoupon');
const couponMessage = document.getElementById('couponMessage');

const activeFilters = {
  category: 'Hepsi',
  price: 'Hepsi',
  search: ''
};

if (mobileNavToggle && siteMenu) {
  mobileNavToggle.addEventListener('click', () => {
    const isExpanded = mobileNavToggle.getAttribute('aria-expanded') === 'true';
    mobileNavToggle.setAttribute('aria-expanded', String(!isExpanded));
    document.body.classList.toggle('nav-open', !isExpanded);
  });

  siteMenu.querySelectorAll('a').forEach((link) => {
    link.addEventListener('click', () => {
      mobileNavToggle.setAttribute('aria-expanded', 'false');
      document.body.classList.remove('nav-open');
    });
  });
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

function formatPrice(value) {
  return Number(value).toLocaleString('tr-TR', {
    style: 'currency',
    currency: 'TRY',
    maximumFractionDigits: 0
  });
}

function safeImageUrl(value) {
  try {
    const url = new URL(value, window.location.href);
    return ['http:', 'https:'].includes(url.protocol) ? url.href : '';
  } catch (error) {
    return '';
  }
}

function safeShopierUrl(value) {
  try {
    const url = new URL(value);
    return url.protocol === 'https:' && (url.hostname === 'shopier.com' || url.hostname.endsWith('.shopier.com'))
      ? url.href
      : '';
  } catch (error) {
    return '';
  }
}

function getCart() {
  try {
    const saved = JSON.parse(localStorage.getItem(cartStorageKey) || '[]');
    if (!Array.isArray(saved)) return [];

    return saved.flatMap((item) => {
      const product = products.find((entry) => entry.id === Number(item?.id));
      const quantity = Number(item?.quantity);
      const safeQuantity = Math.min(quantity, Number(product?.stock || 0));
      return product && Number.isSafeInteger(quantity) && safeQuantity > 0 && safeQuantity <= 20
        ? [{ ...product, quantity: safeQuantity }]
        : [];
    });
  } catch (error) {
    return [];
  }
}

function saveCart(cart) {
  localStorage.setItem(cartStorageKey, JSON.stringify(cart));
}

function getProductById(productId) {
  return products.find((product) => product.id === Number(productId)) || null;
}

function getFavorites() {
  try {
    const saved = JSON.parse(localStorage.getItem(favoriteStorageKey) || '[]');
    return Array.isArray(saved) ? saved : [];
  } catch (error) {
    return [];
  }
}

function saveFavorites(favorites) {
  localStorage.setItem(favoriteStorageKey, JSON.stringify(favorites));
}

function isFavorite(productId) {
  return getFavorites().includes(Number(productId));
}

function toggleFavorite(productId) {
  const favorites = getFavorites();
  const id = Number(productId);

  if (favorites.includes(id)) {
    saveFavorites(favorites.filter((favId) => favId !== id));
    return false;
  }

  favorites.push(id);
  saveFavorites(favorites);
  return true;
}

function getCartCount() {
  return getCart().reduce((total, item) => total + item.quantity, 0);
}

function updateCartCount() {
  if (cartCount) {
    cartCount.textContent = getCartCount();
  }
}

function addToCart(productId) {
  const product = getProductById(productId);
  if (!product) {
    showToast('Ürün bulunamadı. Kataloğu yenileyip tekrar deneyin.');
    return;
  }
  const cart = getCart();
  const index = cart.findIndex((item) => item.id === product.id);

  if (Number(product.stock) <= 0) {
    showToast('Bu ürün şu anda stokta yok.');
    return;
  }

  if (index >= 0 && cart[index].quantity >= product.stock) {
    showToast('Sepetteki adet mevcut stoğa ulaştı.');
    return;
  }

  if (index >= 0) {
    cart[index].quantity += 1;
  } else {
    cart.push({
      id: product.id,
      name: product.name,
      price: product.price,
      icon: product.icon,
      quantity: 1
    });
  }

  saveCart(cart);
  updateCartCount();
  showToast(`${product.name} sepete eklendi.`);
}

function renderWatchFaceMarkers() {
  if (!watchFace) {
    return;
  }

  const markers = Array.from({ length: 12 }, (_, index) => {
    const mark = document.createElement('span');
    mark.className = `watch-mark ${index % 3 === 0 ? 'major' : ''}`;
    mark.style.setProperty('--angle', `${index * 30}deg`);
    return mark;
  });

  watchFace.querySelectorAll('.watch-mark').forEach((mark) => mark.remove());
  markers.forEach((mark) => watchFace.appendChild(mark));
}

function updateAnalogClock() {
  const now = new Date();
  const hours = now.getHours() % 12;
  const minutes = now.getMinutes();
  const seconds = now.getSeconds();

  const hourDegrees = (hours + minutes / 60 + seconds / 3600) * 30;
  const minuteDegrees = (minutes + seconds / 60) * 6;
  const secondDegrees = seconds * 6;

  if (hourHand) {
    hourHand.style.transform = `translate(-50%, -100%) rotate(${hourDegrees}deg)`;
  }

  if (minuteHand) {
    minuteHand.style.transform = `translate(-50%, -100%) rotate(${minuteDegrees}deg)`;
  }

  if (secondHand) {
    secondHand.style.transform = `translate(-50%, -100%) rotate(${secondDegrees}deg)`;
  }

  if (watchTimeLabel) {
    watchTimeLabel.textContent = now.toLocaleTimeString('tr-TR', {
      hour: '2-digit',
      minute: '2-digit'
    });
  }
}

function getFilteredProducts() {
  const searchTerm = activeFilters.search.trim().toLowerCase();

  return products.filter((product) => {
    const matchesCategory =
      activeFilters.category === 'Hepsi' || product.tag === activeFilters.category;
    const matchesSearch =
      !searchTerm || product.name.toLowerCase().includes(searchTerm) || product.tag.toLowerCase().includes(searchTerm);

    let matchesPrice = true;
    if (activeFilters.price === 'Alt3000') {
      matchesPrice = product.price <= 3000;
    }
    if (activeFilters.price === 'Orta') {
      matchesPrice = product.price > 3000 && product.price <= 4000;
    }
    if (activeFilters.price === 'Yuksek') {
      matchesPrice = product.price > 4000;
    }

    return matchesCategory && matchesSearch && matchesPrice;
  });
}

function setCategoryFilter(category) {
  activeFilters.category = category;
  filterButtons.forEach((button) => button.classList.toggle('active', button.dataset.filter === category));
  categoryButtons.forEach((button) => button.classList.toggle('active', button.dataset.filterCategory === category));
  renderProducts();
}

function renderProducts() {
  if (!productGrid) {
    return;
  }

  const visibleProducts = getFilteredProducts();

  if (!visibleProducts.length) {
    productGrid.innerHTML = catalogLoadError
      ? '<div class="empty-state" role="status">Ürün kataloğu şu anda yüklenemiyor. Bağlantınızı kontrol edip yeniden deneyin. <button class="secondary-btn" type="button" data-retry-catalog>Yeniden dene</button></div>'
      : `<div class="empty-state">${products.length ? 'Aradığınız saat bulunamadı.' : 'Henüz satışa açık ürün yok.'}</div>`;
    return;
  }

  productGrid.innerHTML = visibleProducts
    .map(
      (product) => `
        <article class="product-card">
          <div class="product-image">
            <img src="${escapeHTML(safeImageUrl(product.image))}" alt="${escapeHTML(product.name)}" loading="lazy" decoding="async" />
          </div>
          <div class="product-body">
            <div class="card-top-line">
              <span class="product-tag">${escapeHTML(product.tag)}</span>
              <span class="product-badge">${escapeHTML(product.badge)}</span>
            </div>
            <h3>${escapeHTML(product.name)}</h3>
            <p>${escapeHTML(product.description)}</p>
            <p class="stock-label">${Number(product.stock) > 0 ? `Stokta ${Number(product.stock)} adet` : 'Stokta yok'}</p>
            <div class="product-meta">
              <span class="price">${formatPrice(product.price)}</span>
              <div class="product-actions">
                <button class="favorite-btn ${isFavorite(product.id) ? 'active' : ''}" type="button" data-product-id="${product.id}" aria-label="${isFavorite(product.id) ? 'Favorilerden çıkar' : 'Favorilere ekle'}">${isFavorite(product.id) ? '♥' : '♡'}</button>
                <a class="detail-link" href="product-detail.html?id=${product.id}">Detay</a>
                ${Number(product.stock) > 0 && safeShopierUrl(product.paymentUrl) ? `<a class="add-btn payment-link" href="${escapeHTML(safeShopierUrl(product.paymentUrl))}" target="_blank" rel="noopener noreferrer">Shopier'de satın al</a>` : `<button class="add-btn" type="button" data-product-id="${product.id}" ${Number(product.stock) <= 0 ? 'disabled' : ''}>${Number(product.stock) <= 0 ? 'Stokta yok' : 'Sepete ekle'}</button>`}
              </div>
            </div>
          </div>
        </article>
      `
    )
    .join('');
}

function showToast(message) {
  if (!toast) {
    return;
  }

  toast.textContent = message;
  toast.classList.add('show');

  setTimeout(() => {
    toast.classList.remove('show');
  }, 1400);
}

function renderDetailPage() {
  if (!detailName || !detailPrice || !detailTag || !detailDescription || !detailIcon || !detailFeatures) {
    return;
  }
  if (!products.length && !catalogLoadError) return;

  const params = new URLSearchParams(window.location.search);
  const productId = Number(params.get('id'));
  const product = getProductById(productId);
  if (!product) {
    detailName.textContent = catalogLoadError ? 'Ürün bilgileri yüklenemedi' : 'Ürün bulunamadı';
    detailPrice.textContent = '';
    detailTag.textContent = '';
    detailDescription.textContent = catalogLoadError
      ? 'Bağlantınızı kontrol edip ürün kataloğunu yeniden yükleyin.'
      : 'Bu ürün artık mevcut değil. Güncel ürün kataloğunu inceleyebilirsiniz.';
    const stockLabel = document.getElementById('detailStock');
    if (stockLabel) stockLabel.textContent = '';
    detailFeatures.replaceChildren();
    detailAddToCart?.setAttribute('disabled', '');
    if (detailPaymentLink) detailPaymentLink.hidden = true;
    detailIcon.replaceChildren();
    return;
  }

  detailName.textContent = product.name;
  detailPrice.textContent = formatPrice(product.price);
  detailTag.textContent = product.tag;
  detailDescription.textContent = product.description;
  const stockLabel = document.getElementById('detailStock');
  if (stockLabel) stockLabel.textContent = Number(product.stock) > 0 ? `Stokta ${product.stock} adet` : 'Stokta yok';
  const detailImage = document.createElement('img');
  detailImage.src = safeImageUrl(product.image);
  detailImage.alt = product.name;
  detailImage.loading = 'eager';
  detailImage.decoding = 'async';
  detailIcon.replaceChildren(detailImage);
  detailFeatures.innerHTML = product.details.map((feature) => `<li>${escapeHTML(feature)}</li>`).join('');

  if (detailPaymentLink) {
    const paymentUrl = Number(product.stock) > 0 ? safeShopierUrl(product.paymentUrl) : '';
    detailPaymentLink.hidden = !paymentUrl;
    if (paymentUrl) detailPaymentLink.href = paymentUrl;
  }

  if (detailAddToCart) {
    detailAddToCart.setAttribute('data-product-id', String(product.id));
    detailAddToCart.disabled = Number(product.stock) <= 0;
    detailAddToCart.textContent = Number(product.stock) > 0 ? 'Sepete ekle' : 'Stokta yok';
    detailAddToCart.addEventListener('click', () => {
      addToCart(product.id);
    });
  }

  if (detailFavorite) {
    const favoriteState = isFavorite(product.id);
    detailFavorite.textContent = favoriteState ? 'Favorilerden çıkar' : 'Favorilere ekle';
    detailFavorite.classList.toggle('active', favoriteState);
    detailFavorite.onclick = () => {
      const added = toggleFavorite(product.id);
      showToast(added ? 'Favorilere eklendi.' : 'Favorilerden çıkarıldı.');
      renderDetailPage();
    };
  }
}

function getCouponInfo(subtotal) {
  const code = (localStorage.getItem(couponStorageKey) || '').trim().toUpperCase();

  if (code === 'TIME10') {
    return { code, discount: subtotal * 0.1, label: 'TIME10' };
  }

  if (code === 'WATCH15') {
    return { code, discount: subtotal * 0.15, label: 'WATCH15' };
  }

  return { code: '', discount: 0, label: '' };
}

function updateCartPage() {
  if (!cartItems || !cartTotal) {
    return;
  }

  const cart = getCart();
  const subtotal = cart.reduce((sum, item) => sum + item.price * item.quantity, 0);
  const couponInfo = getCouponInfo(subtotal);
  const discount = couponInfo.discount;
  const finalTotal = subtotal - discount;

  if (!cart.length) {
    cartItems.innerHTML = '<div class="empty-state">Sepetiniz şu anda boş.</div>';
    cartTotal.textContent = '₺0';
    if (discountValue) {
      discountValue.textContent = '₺0';
    }
    if (cartTotalFinal) {
      cartTotalFinal.textContent = '₺0';
    }
    return;
  }

  cartItems.innerHTML = cart
    .map(
      (item) => `
        <div class="cart-item">
          <div class="cart-product">
              <div class="cart-image" aria-hidden="true">${escapeHTML(item.icon)}</div>
            <div>
                <h3>${escapeHTML(item.name)}</h3>
                <p>₺${escapeHTML(item.price)} / adet</p>
            </div>
          </div>

          <div class="cart-controls">
            <button class="qty-btn" type="button" data-action="decrease" data-product-id="${item.id}">−</button>
            <span>${item.quantity}</span>
            <button class="qty-btn" type="button" data-action="increase" data-product-id="${item.id}">+</button>
          </div>

          <strong>₺${item.price * item.quantity}</strong>
        </div>
      `
    )
    .join('');

  cartTotal.textContent = formatPrice(subtotal);
  if (discountValue) {
    discountValue.textContent = `-${formatPrice(Math.round(discount))}`;
  }
  if (cartTotalFinal) {
    cartTotalFinal.textContent = formatPrice(Math.round(finalTotal));
  }

  if (couponMessage) {
    if (couponInfo.code) {
      couponMessage.textContent = `${couponInfo.label} kuponu aktif.`;
      couponMessage.classList.add('success');
    } else {
      couponMessage.textContent = 'Kupon ekleyin: TIME10 veya WATCH15';
      couponMessage.classList.remove('success');
    }
  }
}

if (productGrid) {
  productGrid.addEventListener('click', (event) => {
    if (event.target.closest('[data-retry-catalog]')) {
      loadCatalog();
      return;
    }

    const favoriteButton = event.target.closest('.favorite-btn');
    if (favoriteButton) {
      const productId = Number(favoriteButton.dataset.productId);
      const added = toggleFavorite(productId);
      showToast(added ? 'Favorilere eklendi.' : 'Favorilerden çıkarıldı.');
      renderProducts();
      return;
    }

    const button = event.target.closest('.add-btn');

    if (!button) {
      return;
    }

    addToCart(Number(button.dataset.productId));
  });
}

if (searchInput) {
  searchInput.addEventListener('input', (event) => {
    activeFilters.search = event.target.value;
    renderProducts();
  });
}

filterButtons.forEach((button) => {
  button.addEventListener('click', () => {
    setCategoryFilter(button.dataset.filter);
  });
});

categoryButtons.forEach((button) => {
  button.addEventListener('click', () => {
    setCategoryFilter(button.dataset.filterCategory);
    document.getElementById('urunler')?.scrollIntoView({ behavior: 'smooth' });
  });
});

if (priceFilterButtons && priceFilterButtons.length) {
  priceFilterButtons.forEach((button) => {
    button.addEventListener('click', () => {
      activeFilters.price = button.dataset.price;

      priceFilterButtons.forEach((item) => item.classList.toggle('active', item === button));
      renderProducts();
    });
  });
}

if (couponButton && couponInput) {
  couponButton.addEventListener('click', () => {
    const value = couponInput.value.trim();

    if (!value) {
      localStorage.removeItem(couponStorageKey);
      if (couponMessage) {
        couponMessage.textContent = 'Kupon ekleyin: TIME10 veya WATCH15';
        couponMessage.classList.remove('success');
      }
      updateCartPage();
      return;
    }

    const normalized = value.toUpperCase();
    if (normalized === 'TIME10' || normalized === 'WATCH15') {
      localStorage.setItem(couponStorageKey, normalized);
      couponInput.value = normalized;
      if (couponMessage) {
        couponMessage.textContent = `${normalized} kuponu aktif.`;
        couponMessage.classList.add('success');
      }
    } else {
      localStorage.removeItem(couponStorageKey);
      if (couponMessage) {
        couponMessage.textContent = 'Geçersiz kupon kodu.';
        couponMessage.classList.remove('success');
      }
    }

    updateCartPage();
  });
}

if (document.body.dataset.page === 'cart') {
  const checkoutPanel = document.querySelector('.checkout-panel');
  const checkoutUnavailable = document.getElementById('checkoutUnavailable');

  if (checkoutPanel && checkoutUnavailable) {
    fetch('/api/store-config')
      .then((response) => {
        if (!response.ok) throw new Error('Mağaza ayarları yüklenemedi.');
        return response.json();
      })
      .then((config) => {
        if (config.demoCheckoutEnabled === true) {
          checkoutPanel.hidden = false;
          return;
        }

        checkoutUnavailable.textContent = 'Deneme siparişi canlı mağazada kapalıdır. Ödeme bağlantısı bulunan ürünleri Shopier üzerinden satın alabilirsiniz.';
        checkoutUnavailable.hidden = false;
      })
      .catch(() => {
        checkoutUnavailable.textContent = 'Sipariş formu güvenlik için şu anda kapalı. Lütfen daha sonra tekrar deneyin.';
        checkoutUnavailable.hidden = false;
      });
  }

  document.addEventListener('click', (event) => {
    const qtyButton = event.target.closest('.qty-btn');

    if (!qtyButton) {
      return;
    }

    const productId = Number(qtyButton.dataset.productId);
    const action = qtyButton.dataset.action;
    const cart = getCart();
    const itemIndex = cart.findIndex((item) => item.id === productId);

    if (itemIndex === -1) {
      return;
    }

    if (action === 'increase') {
      if (cart[itemIndex].quantity >= cart[itemIndex].stock) {
        showToast('Sepetteki adet mevcut stoğa ulaştı.');
        return;
      }
      cart[itemIndex].quantity += 1;
    }

    if (action === 'decrease') {
      cart[itemIndex].quantity -= 1;

      if (cart[itemIndex].quantity <= 0) {
        cart.splice(itemIndex, 1);
      }
    }

    saveCart(cart);
    updateCartCount();
    updateCartPage();
  });

  if (checkoutForm) {
    checkoutForm.addEventListener('submit', async (event) => {
      event.preventDefault();

      const cart = getCart();

      if (!cart.length) {
        showToast('Sepetiniz boş. Önce ürün ekleyin.');
        return;
      }

      const formData = new FormData(checkoutForm);
      const customerName = formData.get('name') || 'Müşteri';
      try {
        const response = await fetch('/api/orders', {
          method: 'POST',
          headers: { 'Content-Type': 'application/json' },
          body: JSON.stringify({
            customerName,
            email: formData.get('email'),
            phone: formData.get('phone'),
            address: formData.get('address'),
            city: formData.get('city'),
            items: cart.map((item) => ({ id: item.id, quantity: item.quantity })),
            coupon: (localStorage.getItem(couponStorageKey) || '').trim().toUpperCase()
          })
        });

        const result = await response.json();
        if (!response.ok) {
          showToast(result.message || 'Sipariş kaydedilemedi. Bilgilerinizi kontrol edin.');
          return;
        }

        saveCart([]);
        localStorage.removeItem(couponStorageKey);
        updateCartCount();
        updateCartPage();
        checkoutForm.reset();
        window.location.href = `checkout-success.html?name=${encodeURIComponent(customerName)}&order=${encodeURIComponent(result.id)}`;
      } catch (error) {
        showToast('Sunucuya ulaşılamadı. Lütfen tekrar deneyin.');
        return;
      }
    });
  }
}

if (document.body.dataset.page === 'success') {
  const successName = document.getElementById('successName');
  const successOrderId = document.getElementById('successOrderId');
  const params = new URLSearchParams(window.location.search);
  const customerName = params.get('name') || 'Müşteri';

  if (successName) {
    successName.textContent = customerName;
  }

  if (successOrderId) {
    successOrderId.textContent = params.get('order') || '—';
  }

  localStorage.setItem(cartStorageKey, JSON.stringify([]));
  localStorage.removeItem(couponStorageKey);
  updateCartCount();
}

renderWatchFaceMarkers();
updateAnalogClock();
setInterval(updateAnalogClock, 1000);
updateCartCount();

if (document.body.dataset.page === 'cart') {
  updateCartPage();
} else if (document.body.dataset.page === 'success') {
  updateCartCount();
} else if (detailName) {
  renderDetailPage();
} else {
  renderProducts();
}

async function loadCatalog() {
  try {
    const response = await fetch('/api/products');
    if (!response.ok) throw new Error(`Catalog request failed (${response.status}).`);
    const catalog = await response.json();
    if (!Array.isArray(catalog)) throw new Error('Catalog response is invalid.');

    products = catalog.map((product) => ({
      ...product,
      icon: productIcons[product.name] || '⌚',
      details: Array.isArray(product.details) ? product.details : []
    }));
    catalogLoadError = false;
    if (catalogCount) catalogCount.textContent = String(products.length);
    updateCartCount();

    if (document.body.dataset.page === 'cart') {
      updateCartPage();
    } else if (detailName) {
      renderDetailPage();
    } else {
      renderProducts();
    }
  } catch (error) {
    console.error('Product catalog could not be loaded:', error);
    catalogLoadError = true;
    if (productGrid) renderProducts();
    if (detailName) renderDetailPage();
  }
}

loadCatalog();
