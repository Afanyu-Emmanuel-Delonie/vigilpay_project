/* Consolidated scripts: base + dashboard + login */

(function () {
  if (!document.getElementById('sidebar')) return;

  const sidebar     = document.getElementById('sidebar');
  const mainContent = document.getElementById('mainContent');
  const overlay     = document.getElementById('mobileOverlay');
  const toggleBtn   = document.getElementById('toggleSidebar');
  const toggleIcon  = document.getElementById('toggleIcon');
  const openBtn     = document.getElementById('openSidebar');
  const closeBtn    = document.getElementById('closeSidebar');

  /* ── Collapse state ─────────────────────── */
  let collapsed = localStorage.getItem('vpSidebarCollapsed') === 'true';

  function applyCollapsed(animate) {
    if (collapsed) {
      sidebar.classList.add('is-collapsed');
      mainContent.classList.add('sidebar-collapsed');
      toggleIcon.style.transform = 'rotate(180deg)';
    } else {
      sidebar.classList.remove('is-collapsed');
      mainContent.classList.remove('sidebar-collapsed');
      toggleIcon.style.transform = 'rotate(0deg)';
    }
    localStorage.setItem('vpSidebarCollapsed', collapsed);
  }

  // Apply on load (no animation)
  if (window.innerWidth >= 1024) applyCollapsed(false);

  toggleBtn?.addEventListener('click', () => {
    collapsed = !collapsed;
    applyCollapsed(true);
  });

  /* ── Mobile sidebar ─────────────────────── */
  function openMobile()  {
    sidebar.classList.add('mobile-open');
    overlay.classList.add('visible');
    document.body.style.overflow = 'hidden';
  }
  function closeMobile() {
    sidebar.classList.remove('mobile-open');
    overlay.classList.remove('visible');
    document.body.style.overflow = '';
  }

  openBtn?.addEventListener('click', openMobile);
  closeBtn?.addEventListener('click', closeMobile);
  overlay?.addEventListener('click', closeMobile);
  sidebar.querySelectorAll('a').forEach(a => {
    a.addEventListener('click', () => { if (window.innerWidth < 1024) closeMobile(); });
  });

  window.addEventListener('resize', () => {
    if (window.innerWidth >= 1024) {
      closeMobile();
      applyCollapsed(false);
    }
  }, { passive: true });

  /* ── Active nav highlight ───────────────────
     Strategy: match by URL path first.
     If multiple links share the same path (as
     in this template), also check a
     data-active-key attribute set by child
     templates, or default to the first match.
  ─────────────────────────────────────────── */
  const currentPath   = window.location.pathname;
  // Child templates can set: <meta name="active-nav" content="risk">
  const activeKeyMeta = document.querySelector('meta[name="active-nav"]');
  const activeKey     = activeKeyMeta ? activeKeyMeta.getAttribute('content') : null;

  const navLinks = sidebar.querySelectorAll('.nav-item a');

  if (activeKey) {
    // Explicit key match (most reliable)
    navLinks.forEach(link => {
      if (link.dataset.navkey === activeKey) link.classList.add('active');
    });
  } else {
    // Fallback: path match — highlight first exact match
    let matched = false;
    navLinks.forEach(link => {
      if (!matched && link.getAttribute('href') === currentPath) {
        link.classList.add('active');
        matched = true;
      }
    });
    // If still no match, highlight first link as default
    if (!matched && navLinks.length) navLinks[0].classList.add('active');
  }

  /* ── Topbar scroll shadow ───────────────── */
  const topbar = document.getElementById('topbar');
  window.addEventListener('scroll', () => {
    topbar.classList.toggle('scrolled', window.scrollY > 10);
  }, { passive: true });

  /* ── User dropdown ──────────────────────── */
  const userBtn      = document.getElementById('userMenuButton');
  const userDropdown = document.getElementById('userDropdown');
  userBtn?.addEventListener('click', e => { e.stopPropagation(); userDropdown.classList.toggle('hidden'); });
  document.addEventListener('click', () => userDropdown?.classList.add('hidden'));
  document.addEventListener('keydown', e => { if (e.key === 'Escape') userDropdown?.classList.add('hidden'); });

})();

(function () {
  const input = document.getElementById('globalSearchInput');
  const list = document.getElementById('globalSearchResults');
  if (!input || !list) return;

  const endpoint = input.dataset.searchUrl;
  if (!endpoint) return;

  let timer = null;
  let activeIndex = -1;
  let currentItems = [];
  let controller = null;

  function riskClass(level) {
    const lower = (level || '').toLowerCase();
    if (lower === 'high' || lower === 'medium' || lower === 'low') return lower;
    return 'low';
  }

  function esc(value) {
    return String(value ?? '')
      .replace(/&/g, '&amp;')
      .replace(/</g, '&lt;')
      .replace(/>/g, '&gt;')
      .replace(/"/g, '&quot;')
      .replace(/'/g, '&#39;');
  }

  function hideList() {
    list.classList.add('hidden');
    activeIndex = -1;
    currentItems = [];
  }

  function renderResults(data) {
    const results = data.results || [];
    currentItems = results;
    activeIndex = -1;

    if (!results.length) {
      list.innerHTML = '<div class="search-empty">No customer matches found.</div>';
      list.classList.remove('hidden');
      return;
    }

    list.innerHTML = results.map((item, idx) => {
      const cls = riskClass(item.risk_level);
      const goto = `${item.risk_url}?q=${encodeURIComponent(item.customer_id)}`;
      return `
        <a class="search-result-item" data-index="${idx}" href="${goto}">
          <div class="search-result-title">${esc(item.surname)} (ID: ${esc(item.customer_id)})</div>
          <div class="search-result-line">
            <span>${esc(item.geography)} • ${esc(item.gender)}</span>
            <span class="search-risk-pill ${cls}">${esc(item.risk_score)}% ${esc(item.risk_level)}</span>
          </div>
          <div class="search-result-line">
            <span>${esc(item.driver)}</span>
          </div>
        </a>
      `;
    }).join('');

    list.classList.remove('hidden');
  }

  async function runSearch() {
    const query = input.value.trim();
    if (query.length < 2) {
      hideList();
      return;
    }

    if (controller) controller.abort();
    controller = new AbortController();

    try {
      const url = `${endpoint}?q=${encodeURIComponent(query)}`;
      const response = await fetch(url, { signal: controller.signal });
      if (!response.ok) throw new Error('search request failed');
      const data = await response.json();
      renderResults(data);
    } catch (err) {
      if (err.name === 'AbortError') return;
      list.innerHTML = '<div class="search-empty">Search temporarily unavailable.</div>';
      list.classList.remove('hidden');
    }
  }

  input.addEventListener('input', () => {
    clearTimeout(timer);
    timer = setTimeout(runSearch, 280);
  });

  input.addEventListener('keydown', (event) => {
    const items = Array.from(list.querySelectorAll('.search-result-item'));
    if (!items.length) return;

    if (event.key === 'ArrowDown') {
      event.preventDefault();
      activeIndex = (activeIndex + 1) % items.length;
    } else if (event.key === 'ArrowUp') {
      event.preventDefault();
      activeIndex = (activeIndex - 1 + items.length) % items.length;
    } else if (event.key === 'Enter') {
      event.preventDefault();
      const activeItem = items[activeIndex] || items[0];
      activeItem?.click();
      return;
    } else if (event.key === 'Escape') {
      hideList();
      return;
    } else {
      return;
    }

    items.forEach((el, idx) => el.classList.toggle('active', idx === activeIndex));
  });

  document.addEventListener('click', (event) => {
    if (event.target === input) return;
    if (!list.contains(event.target)) hideList();
  });
})();

(function () {
  if (!document.getElementById('chartBar')) return;
  if (typeof Chart === 'undefined') return;

  Chart.defaults.font.family  = "'Poppins', system-ui, sans-serif";
  Chart.defaults.font.size    = 11;
  Chart.defaults.color        = '#aaa';
  Chart.defaults.plugins.legend.display = false;

  const RED = '#8C1515';
  const GOLD = '#C9A84C';

  let dashboardData = null;
  const dataNode = document.getElementById('dashboard-data');
  if (dataNode) {
    try {
      dashboardData = JSON.parse(dataNode.textContent);
    } catch (_e) {
      dashboardData = null;
    }
  }

  const barLabels = dashboardData?.bar?.labels || ['Low Risk', 'Medium Risk', 'High Risk'];
  const barValues = dashboardData?.bar?.values || [0, 0, 0];
  const donutLabels = dashboardData?.donut?.labels || [];
  const donutValues = dashboardData?.donut?.values || [];
  const scatterHigh = dashboardData?.scatter?.high || [];
  const scatterLow = dashboardData?.scatter?.low || [];
  const lineLabels = dashboardData?.line?.labels || [];
  const lineValues = dashboardData?.line?.values || [];

  new Chart(document.getElementById('chartBar'), {
    type: 'bar',
    data: {
      labels: barLabels,
      datasets: [{
        data: barValues,
        backgroundColor: ['rgba(5,150,105,0.15)', 'rgba(201,168,76,0.25)', 'rgba(140,21,21,0.2)'],
        borderColor: ['#059669', GOLD, RED],
        borderWidth: 2, borderRadius: 8, borderSkipped: false,
      }]
    },
    options: {
      responsive: true, maintainAspectRatio: false,
      plugins: { tooltip: { callbacks: { label: ctx => ` ${ctx.parsed.y.toLocaleString()} customers` } } },
      scales: {
        x: { grid: { display: false }, border: { display: false }, ticks: { font: { weight: '600' } } },
        y: { grid: { color: '#f0ece7' }, border: { display: false }, ticks: { callback: v => v.toLocaleString() } }
      }
    }
  });

  new Chart(document.getElementById('chartDonut'), {
    type: 'doughnut',
    data: {
      labels: donutLabels,
      datasets: [{
        data: donutValues,
        backgroundColor: [RED, GOLD, '#374151', '#0f766e', '#7c3aed', '#2563eb'],
        borderColor: '#fff', borderWidth: 3, hoverOffset: 6,
      }]
    },
    options: {
      responsive: true, maintainAspectRatio: false, cutout: '68%',
      plugins: {
        legend: { display: true, position: 'bottom', labels: { boxWidth: 10, boxHeight: 10, borderRadius: 3, padding: 14, font: { weight: '600' } } },
        tooltip: { callbacks: { label: ctx => ` ${ctx.label}: ${ctx.parsed.toLocaleString()} customers` } }
      }
    }
  });

  new Chart(document.getElementById('chartScatter'), {
    type: 'scatter',
    data: { datasets: [
      { label: 'Higher Risk', data: scatterHigh, backgroundColor: 'rgba(140,21,21,0.55)', pointRadius: 4, pointHoverRadius: 6 },
      { label: 'Lower Risk', data: scatterLow, backgroundColor: 'rgba(196,187,176,0.5)', pointRadius: 3, pointHoverRadius: 5 }
    ]},
    options: {
      responsive: true, maintainAspectRatio: false,
      scales: {
        x: { title: { display: true, text: 'Age', font: { weight: '700' }, color: '#bbb' }, grid: { color: '#f0ece7' }, border: { display: false } },
        y: { title: { display: true, text: 'Balance ($)', font: { weight: '700' }, color: '#bbb' }, grid: { color: '#f0ece7' }, border: { display: false }, ticks: { callback: v => '$' + (v/1000).toFixed(0) + 'k' } }
      },
      plugins: { legend: { display: false }, tooltip: { callbacks: { label: ctx => ` Age ${ctx.parsed.x}, $${ctx.parsed.y.toLocaleString()}` } } }
    }
  });

  new Chart(document.getElementById('chartLine'), {
    type: 'line',
    data: {
      labels: lineLabels,
      datasets: [{
        data: lineValues,
        borderColor: RED, backgroundColor: 'rgba(140,21,21,0.07)',
        fill: true, tension: 0.42,
        pointBackgroundColor: RED, pointBorderColor: '#fff',
        pointBorderWidth: 2, pointRadius: 5, pointHoverRadius: 7,
      }]
    },
    options: {
      responsive: true, maintainAspectRatio: false,
      scales: {
        x: { grid: { display: false }, border: { display: false }, ticks: { font: { weight: '600' } } },
        y: { grid: { color: '#f0ece7' }, border: { display: false }, ticks: { callback: v => v + '%' } }
      },
      plugins: { tooltip: { callbacks: { label: ctx => ` Average Risk: ${ctx.parsed.y}%` } } }
    }
  });

const io = new IntersectionObserver(entries => {
  entries.forEach(e => {
    if (e.isIntersecting) {
      document.querySelectorAll('.fi-fill[data-w]').forEach(bar => { bar.style.width = bar.dataset.w + '%'; });
      io.disconnect();
    }
  });
}, { threshold: 0.3 });
io.observe(document.getElementById('fi-bars'));

function runSim() {
  const credit  = +document.getElementById('simCredit').value;
  const balance = +document.getElementById('simBalance').value;
  const age     = +document.getElementById('simAge').value;
  const prods   = +document.getElementById('simProd').value;

  document.getElementById('simCreditVal').textContent  = credit;
  document.getElementById('simBalanceVal').textContent = '$' + balance.toLocaleString();
  document.getElementById('simAgeVal').textContent     = age;
  document.getElementById('simProdVal').textContent    = prods;

  let risk = 50;
  risk += (850 - credit) / 850 * 25;
  risk -= Math.min(balance / 200000 * 20, 20);
  if (age > 45 || age < 28) risk += 10;
  risk -= (prods - 1) * 12;
  risk = Math.max(5, Math.min(97, Math.round(risk)));

  const circ = 163.36;
  const fill = document.getElementById('gaugeFill');
  fill.style.strokeDashoffset = circ - (risk / 100) * circ;
  fill.style.stroke = risk >= 75 ? '#8C1515' : risk >= 45 ? '#C9A84C' : '#059669';
  document.getElementById('gaugeLabel').textContent = risk + '%';

  const vEl = document.getElementById('simVerdict');
  const dEl = document.getElementById('simDesc');
  if (risk >= 75) {
    vEl.textContent = 'High Risk — Intervene Now'; vEl.style.color = '#f87171';
    dEl.textContent = 'This customer is very likely to churn. Immediate outreach with a targeted retention offer is recommended.';
  } else if (risk >= 45) {
    vEl.textContent = 'Medium Risk — Monitor'; vEl.style.color = '#fbbf24';
    dEl.textContent = 'Moderate churn likelihood. Schedule a check-in and consider a product upgrade or loyalty benefit.';
  } else {
    vEl.textContent = 'Low Risk — Retain Focus'; vEl.style.color = '#34d399';
    dEl.textContent = 'This customer profile is stable. Focus resources on higher-risk segments.';
  }
}
runSim();

})();

(function () {
  if (!document.getElementById('loginForm')) return;

      // ── Password visibility toggle ─────────────
      const pwToggle = document.getElementById("pw-toggle");
      const pwInput = document.getElementById("password");
      const eyeIcon = document.getElementById("eye-icon");

      const eyeOpen = `<path d="M1 10s3.5-6 9-6 9 6 9 6-3.5 6-9 6-9-6-9-6z" stroke="currentColor" stroke-width="1.5"/><circle cx="10" cy="10" r="2.5" stroke="currentColor" stroke-width="1.5"/>`;
      const eyeOff = `<path d="M3 3l14 14M10.5 6A9.2 9.2 0 0119 10s-1.3 2.5-3.8 4.2M6.5 6.5C3.9 8 2 10 2 10s3.5 6 8 6c1.5 0 2.9-.4 4.1-1.1" stroke="currentColor" stroke-width="1.5" stroke-linecap="round"/>`;

      pwToggle.addEventListener("click", () => {
        const isHidden = pwInput.type === "password";
        pwInput.type = isHidden ? "text" : "password";
        eyeIcon.innerHTML = isHidden ? eyeOff : eyeOpen;
      });

      // ── Form validation & submit ───────────────
      const form = document.getElementById("loginForm");
      const loginBtn = document.getElementById("loginBtn");
      const emailFld = document.getElementById("field-email");
      const passFld = document.getElementById("field-password");
      const emailInp = document.getElementById("email");
      const passInp = document.getElementById("password");

      function validateEmail(v) {
        return /^[^\s@]+@[^\s@]+\.[^\s@]+$/.test(v);
      }

      emailInp.addEventListener("input", () => {
        if (
          emailFld.classList.contains("error") &&
          validateEmail(emailInp.value.trim())
        ) {
          emailFld.classList.remove("error");
        }
      });
      passInp.addEventListener("input", () => {
        if (passFld.classList.contains("error") && passInp.value.length > 0) {
          passFld.classList.remove("error");
        }
      });

      form.addEventListener("submit", async (e) => {
        e.preventDefault();
        let valid = true;

        if (!validateEmail(emailInp.value.trim())) {
          emailFld.classList.add("error");
          valid = false;
        } else {
          emailFld.classList.remove("error");
        }

        if (passInp.value.length === 0) {
          passFld.classList.add("error");
          valid = false;
        } else {
          passFld.classList.remove("error");
        }

        if (!valid) return;

        // Show loading
        loginBtn.classList.add("loading");
        loginBtn.disabled = true;

        // ── Submit to Django view ──────────────────
        // Replace the timeout below with your actual fetch/form submit:
        //
        // const resp = await fetch('/login/', {
        //   method: 'POST',
        //   headers: { 'X-CSRFToken': getCookie('csrftoken'), 'Content-Type': 'application/json' },
        //   body: JSON.stringify({ email: emailInp.value.trim(), password: passInp.value })
        // });
        // if (resp.ok) { window.location.href = '/dashboard/'; }
        // else { showError(); }

        setTimeout(() => {
          loginBtn.classList.remove("loading");
          loginBtn.disabled = false;
          // Simulate: remove this in production
          form.submit();
        }, 1400);
      });

      // CSRF helper for Django
      function getCookie(name) {
        let cv = null;
        if (document.cookie && document.cookie !== "") {
          for (const c of document.cookie.split(";")) {
            const t = c.trim();
            if (t.startsWith(name + "=")) {
              cv = decodeURIComponent(t.slice(name.length + 1));
              break;
            }
          }
        }
        return cv;
      }
    
})();

(function () {
  const activeMeta = document.querySelector('meta[name="active-nav"]');
  if (!activeMeta || activeMeta.getAttribute('content') !== 'risk') return;

  /* ── Debounced search submit ── */
  let _searchTimer;
  function debounceSearch(form) {
    clearTimeout(_searchTimer);
    _searchTimer = setTimeout(() => form.submit(), 480);
  }

  /* ── Client-side filter (demo — remove when Django view handles it) ── */
  const riskSelect   = document.querySelector('[name="risk_level"]');
  const geoSelect    = document.querySelector('[name="geography"]');
  const activeSelect = document.querySelector('[name="is_active"]');
  const searchInput  = document.querySelector('[name="q"]');
  const tableBody    = document.getElementById('tableBody');
  const emptyState   = document.getElementById('emptyState');

  function filterTable() {
    const risk   = riskSelect?.value   || '';
    const geo    = geoSelect?.value    || '';
    const active = activeSelect?.value || '';
    const q      = (searchInput?.value || '').toLowerCase();

    const rows = tableBody.querySelectorAll('tr');
    let visible = 0;

    rows.forEach(row => {
      const name    = row.querySelector('.customer-av')?.nextElementSibling?.querySelector('div')?.textContent?.toLowerCase() || '';
      const cid     = row.querySelector('.cid')?.textContent?.toLowerCase() || '';
      const badgeEl = row.querySelector('.risk-badge');
      const badge   = badgeEl ? (badgeEl.classList.contains('high') ? 'high' : badgeEl.classList.contains('medium') ? 'medium' : 'low') : '';
      const statusEl = row.querySelectorAll('td')[5];
      const isActive = statusEl?.textContent?.trim() === 'Active';

      let show = true;
      if (risk   && badge !== risk)                         show = false;
      if (active === '1' && !isActive)                      show = false;
      if (active === '0' && isActive)                       show = false;
      if (q && !name.includes(q) && !cid.includes(q))      show = false;

      row.style.display = show ? '' : 'none';
      if (show) visible++;
    });

    emptyState.classList.toggle('visible', visible === 0);

    // Update summary counts
    updateCounts(rows);
  }

  function updateCounts(rows) {
    let total = 0, high = 0, medium = 0, low = 0;
    rows.forEach(row => {
      if (row.style.display === 'none') return;
      total++;
      const b = row.querySelector('.risk-badge');
      if (!b) return;
      if (b.classList.contains('high'))   high++;
      if (b.classList.contains('medium')) medium++;
      if (b.classList.contains('low'))    low++;
    });
    animateCount('cnt-total', total);
    animateCount('cnt-high', high);
    animateCount('cnt-medium', medium);
    animateCount('cnt-low', low);
  }

  function animateCount(id, target) {
    const el = document.getElementById(id);
    if (!el) return;
    const start = parseInt(el.textContent.replace(/,/g,'')) || 0;
    const dur = 300;
    const t0 = performance.now();
    const step = ts => {
      const p = Math.min((ts - t0) / dur, 1);
      const ease = 1 - Math.pow(1 - p, 3);
      el.textContent = Math.round(start + (target - start) * ease).toLocaleString();
      if (p < 1) requestAnimationFrame(step);
    };
    requestAnimationFrame(step);
  }

  /* ── Column sort (client-side) ── */
  document.querySelectorAll('.risk-table th.sortable').forEach(th => {
    th.addEventListener('click', () => {
      const col     = th.dataset.col;
      const asc     = th.classList.contains('sorted') ? !th.dataset.asc : true;
      th.dataset.asc = asc;

      document.querySelectorAll('.risk-table th').forEach(h => { h.classList.remove('sorted'); h.dataset.asc = ''; h.querySelector('.sort-icon').textContent = '↕'; });
      th.classList.add('sorted');
      th.querySelector('.sort-icon').textContent = asc ? '↑' : '↓';

      const rows = Array.from(tableBody.querySelectorAll('tr'));
      rows.sort((a, b) => {
        let av, bv;
        if (col === 'risk') {
          av = parseFloat(a.querySelector('.risk-badge')?.textContent) || 0;
          bv = parseFloat(b.querySelector('.risk-badge')?.textContent) || 0;
        } else if (col === 'balance') {
          av = parseFloat(a.querySelectorAll('td')[4]?.textContent?.replace(/[$,]/g,'')) || 0;
          bv = parseFloat(b.querySelectorAll('td')[4]?.textContent?.replace(/[$,]/g,'')) || 0;
        }
        return asc ? bv - av : av - bv;
      });

      rows.forEach((r, i) => {
        tableBody.appendChild(r);
        const rankEl = r.querySelector('.rank-badge');
        if (rankEl) {
          rankEl.textContent = i + 1;
          rankEl.classList.toggle('top3', i < 3);
        }
      });
    });
  });

  /* ── Live client-side filtering (for demo) ── */
  riskSelect?.addEventListener('change', filterTable);
  geoSelect?.addEventListener('change', filterTable);
  activeSelect?.addEventListener('change', filterTable);
  searchInput?.addEventListener('input', () => { clearTimeout(_searchTimer); _searchTimer = setTimeout(filterTable, 300); });

})();


(function () {
  if (!document.getElementById('navbar')) return;

      // Feather icons (guarded so nav init still runs if CDN script is unavailable)
      if (typeof feather !== "undefined") {
        feather.replace({ "stroke-width": 1.75 });
      }

      // Navbar scroll effect
      const nav = document.getElementById("navbar");
      window.addEventListener(
        "scroll",
        () => {
          nav.classList.toggle("scrolled", window.scrollY > 20);
        },
        { passive: true },
      );

      // Mobile menu toggle
      let mobileOpen = false;
      function toggleNav() {
        mobileOpen = !mobileOpen;
        document
          .getElementById("mobile-nav")
          .classList.toggle("open", mobileOpen);
        const h1 = document.getElementById("hb1"),
          h2 = document.getElementById("hb2"),
          h3 = document.getElementById("hb3");
        if (mobileOpen) {
          h1.style.transform = "rotate(45deg) translate(4px,4px)";
          h2.style.opacity = "0";
          h3.style.transform = "rotate(-45deg) translate(4px,-4px)";
        } else {
          h1.style.transform = "";
          h2.style.opacity = "";
          h3.style.transform = "";
        }
      }
      function closeNav() {
        mobileOpen = false;
        document.getElementById("mobile-nav").classList.remove("open");
        ["hb1", "hb2", "hb3"].forEach((id) => {
          const el = document.getElementById(id);
          el.style.transform = "";
          el.style.opacity = "";
        });
      }
      window.toggleNav = toggleNav;
      window.closeNav = closeNav;

      // Demo modal
      function openDemo() {
        const m = document.getElementById("demo-modal"),
          b = document.getElementById("demo-box");
        m.style.display = "flex";
        document.body.style.overflow = "hidden";
        requestAnimationFrame(() =>
          requestAnimationFrame(() => {
            b.style.transform = "scale(1)";
            b.style.opacity = "1";
          }),
        );
      }
      function closeDemo() {
        const m = document.getElementById("demo-modal"),
          b = document.getElementById("demo-box");
        b.style.transform = "scale(0.93)";
        b.style.opacity = "0";
        setTimeout(() => {
          m.style.display = "none";
          document.body.style.overflow = "";
        }, 280);
      }
      window.closeDemo = closeDemo;
      document.getElementById("demo-modal").addEventListener("click", (e) => {
        if (e.target === e.currentTarget) closeDemo();
      });
      document.querySelectorAll('[href="#demo"]').forEach((el) =>
        el.addEventListener("click", (e) => {
          e.preventDefault();
          openDemo();
        }),
      );
      document.addEventListener("keydown", (e) => {
        if (e.key === "Escape") closeDemo();
      });

      // Scroll reveal
      const io = new IntersectionObserver(
        (entries) => {
          entries.forEach((e) => {
            if (e.isIntersecting) {
              e.target.classList.add("in");
              io.unobserve(e.target);
            }
          });
        },
        { threshold: 0.1, rootMargin: "0px 0px -36px 0px" },
      );
      document.querySelectorAll(".sr").forEach((el) => io.observe(el));

      // Risk bar animations
      document.querySelectorAll(".bar-fill[data-w]").forEach((bar) => {
        const bIO = new IntersectionObserver(
          (entries) => {
            entries.forEach((e) => {
              if (e.isIntersecting) {
                setTimeout(() => {
                  bar.style.width = bar.getAttribute("data-w") + "%";
                }, 150);
                bIO.unobserve(e.target);
              }
            });
          },
          { threshold: 0.6 },
        );
        bIO.observe(bar.closest(".bar-track") || bar);
      });

      // Smooth scroll for anchor links
      document.querySelectorAll('a[href^="#"]').forEach((a) => {
        a.addEventListener("click", function (e) {
          const id = this.getAttribute("href");
          if (id === "#" || id === "#demo") return;
          const target = document.querySelector(id);
          if (target) {
            e.preventDefault();
            target.scrollIntoView({ behavior: "smooth", block: "start" });
          }
        });
      });
    
})();

