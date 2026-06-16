/* ============================================================
   WAREHOUSE EMPIRE – NUI Game Display Layer
   Receives state from client.lua, renders UI, sends actions back
   ============================================================ */
'use strict';

// ════════════════════ STATE ════════════════════

let CFG       = {};
let UPGRADES  = [];
let MAT_ORDER = {};
let G         = null;
let whName    = '';
let playerCash = 0;

let activityLog = [];
const MAX_LOG = 40;
let _lastUpgradeSnap = '';

// Combo tracking
let comboCount = 0;
let comboTimer = null;
const COMBO_TIMEOUT = 1200; // ms before combo resets

// ════════════════════ HELPERS ════════════════════

function fmt$(n) {
    if (n >= 1e12) return '$' + (n / 1e12).toFixed(2) + 'T';
    if (n >= 1e9)  return '$' + (n / 1e9).toFixed(2) + 'B';
    if (n >= 1e6)  return '$' + (n / 1e6).toFixed(2) + 'M';
    if (n >= 1e3)  return '$' + (n / 1e3).toFixed(2) + 'K';
    return '$' + Math.floor(n);
}
function fmtN(n) {
    if (n >= 1e12) return (n / 1e12).toFixed(2) + 'T';
    if (n >= 1e9)  return (n / 1e9).toFixed(2) + 'B';
    if (n >= 1e6)  return (n / 1e6).toFixed(2) + 'M';
    if (n >= 1e3)  return (n / 1e3).toFixed(1) + 'K';
    return Math.floor(n).toString();
}
function fmtTime(s) {
    s = Math.ceil(s);
    const m = Math.floor(s / 60);
    const sec = s % 60;
    return m > 0 ? `${m}m ${sec.toString().padStart(2, '0')}s` : `${sec}s`;
}

// ═══ Derived values ═══

function getCapacity()          { return CFG.INITIAL_CAPACITY + (G.upgrades.storage || 0) * CFG.STORAGE_PER_UPGRADE; }
function getClickPower()        { return CFG.INITIAL_CLICK_POWER + (G.upgrades.click_power || 0); }
function getMatPerBox()         { return Math.max(1, CFG.MAT_BASE_COST - (G.upgrades.mat_efficiency || 0)); }
function getBoxValue()          { return CFG.BOX_BASE_VALUE + (G.upgrades.box_value || 0) * CFG.BOX_VALUE_PER_UPGRADE; }
function getMaxDeliveries()     { return CFG.INITIAL_DELIVERY_SLOTS + (G.upgrades.del_slots || 0); }
function getDeliverySpeedMult() { return Math.pow(CFG.DELIVERY_SPEED_FACTOR, G.upgrades.del_speed || 0); }
function getOrderSpeedMult()    { return Math.pow(CFG.ORDER_SPEED_FACTOR, G.upgrades.order_speed || 0); }
function getAutoPackRate()      { return G.upgrades.auto_pack || 0; }
function getOrderAmount()       { return CFG.BASE_ORDER_AMOUNT + (G.upgrades.order_capacity || 0) * CFG.ORDER_AMOUNT_PER_UPGRADE; }

function getDeliveryBonusMult(boxCount) {
    return boxCount * CFG.MAX_BONUS_MULT / (CFG.MAX_STORAGE_UPGRADES * CFG.STORAGE_PER_UPGRADE);
}
function getDeliveryTime(boxCount) {
    return (CFG.BASE_DELIVERY_TIME + boxCount * CFG.DELIVERY_TIME_PER_BOX) * getDeliverySpeedMult();
}
function getDeliveryPayout(boxCount) {
    const base = boxCount * getBoxValue();
    const bonus = getDeliveryBonusMult(boxCount);
    return Math.floor(base * (1 + bonus));
}
function getManualBonusMult(boxCount) {
    return boxCount * CFG.MANUAL_BONUS_MULT / (CFG.MAX_STORAGE_UPGRADES * CFG.STORAGE_PER_UPGRADE);
}
function getManualPayout(boxCount) {
    const base = boxCount * getBoxValue();
    const bonus = getManualBonusMult(boxCount);
    return Math.floor(base * (1 + bonus));
}
function getUpgradeCost(id) {
    const def = UPGRADES.find(u => u.id === id);
    if (!def) return 999999999;
    return Math.floor(def.baseCost * Math.pow(def.mult, G.upgrades[id] || 0));
}

// ════════════════════ NUI FETCH HELPER ════════════════════

function nuiCallback(name, data = {}) {
    return fetch(`https://${GetParentResourceName()}/${name}`, {
        method: 'POST',
        headers: { 'Content-Type': 'application/json; charset=UTF-8' },
        body: JSON.stringify(data),
    }).then(r => r.text()).then(t => {
        try { return JSON.parse(t); } catch(e) { return {}; }
    }).catch(() => ({}));
}

// ════════════════════ NUI MESSAGE HANDLER ════════════════════

window.addEventListener('message', function(event) {
    const data = event.data;

    switch (data.action) {
        case 'init':
            CFG       = data.config   || {};
            UPGRADES  = data.upgrades || [];
            MAT_ORDER = data.matOrder || {};
            G         = data.state    || {};
            whName    = data.whName   || 'Warehouse';
            playerCash = data.playerCash || 0;
            activityLog = [];
            addLog('system', `🏭 Managing: ${whName}`);

            document.getElementById('warehouse-title').textContent = whName;
            document.body.style.display = '';

            renderMaterialOrders();
            renderDeliveryOptions();
            renderUpgrades();
            renderActivityFeed();
            updateUI();
            switchTab('dashboard');
            break;

        case 'updateState':
            if (data.state) {
                G = data.state;
                if (data.playerCash !== undefined) playerCash = data.playerCash;
                updateUI();
            }
            break;

        case 'hide':
            document.body.style.display = 'none';
            break;
    }
});

// ════════════════════ GAME ACTIONS ════════════════════

function doClick(e) {
    if (!G) return;
    if (G.materials < getMatPerBox() || G.boxes >= getCapacity()) return;

    // Increment combo
    comboCount++;
    if (comboTimer) clearTimeout(comboTimer);
    comboTimer = setTimeout(() => { comboCount = 0; }, COMBO_TIMEOUT);

    // Track max combo in stats
    if (G.stats && comboCount > (G.stats.maxCombo || 1)) {
        G.stats.maxCombo = comboCount;
    }

    // Update combo display immediately
    const comboEl = document.getElementById('display-combo');
    if (comboEl) {
        comboEl.textContent = 'x' + comboCount;
        comboEl.classList.remove('combo-pulse');
        void comboEl.offsetWidth; // reflow to retrigger animation
        comboEl.classList.add('combo-pulse');
    }

    nuiCallback('doClick').then(res => {
        if (res.boxesMade && res.boxesMade > 0) {
            spawnParticle(e, res.boxesMade);
            const btn = document.getElementById('main-click-btn');
            btn.classList.add('click-flash');
            setTimeout(() => btn.classList.remove('click-flash'), 100);
        }
    });
}

function orderMaterials() {
    if (!G || G.money < CFG.BASE_ORDER_COST) return;
    addLog('order', `📋 Ordered ${MAT_ORDER.name || 'Supply Shipment'} (${fmtN(getOrderAmount())} mats) for ${fmt$(CFG.BASE_ORDER_COST)}`);
    nuiCallback('orderMaterials');
}

function sendAllBoxes() {
    if (!G || G.boxes <= 0) return;
    const boxCount = G.boxes;
    const payout = getDeliveryPayout(boxCount);
    const bonusPct = Math.round(getDeliveryBonusMult(boxCount) * 100);
    addLog('delivery', `🚚 Sent ${fmtN(boxCount)} boxes → ${fmt$(payout)} (+${bonusPct}% volume bonus)`);
    nuiCallback('sendAllBoxes');
}

function manualDeliver() {
    if (!G || G.boxes <= 0) return;
    const boxCount = G.boxes;
    const payout = getManualPayout(boxCount);
    addLog('delivery', `🤝 Manual delivery started: ${fmtN(boxCount)} boxes → ${fmt$(payout)}`);
    nuiCallback('manualDeliver').then(res => {
        if (res.ok && res.destName) {
            showToast('Delivery Started!', `Drive to ${res.destName} for ${fmt$(res.payout || payout)}`, 'info');
        }
    });
}

function buyUpgrade(id) {
    if (!G) return;
    const cost = getUpgradeCost(id);
    if (G.money < cost) return;
    const def = UPGRADES.find(u => u.id === id);
    const newLevel = (G.upgrades[id] || 0) + 1;

    // Optimistic local update
    G.upgrades[id] = newLevel;
    G.money = Math.max(0, G.money - cost);

    addLog('upgrade', `⬆️ Upgraded ${def ? def.name : id} to Lv ${newLevel}`);
    showToast('Upgrade!', `${def ? def.name : id} → Level ${newLevel}`, 'primary');
    renderUpgrades();
    renderMaterialOrders();
    renderDeliveryOptions();
    updateUI();

    nuiCallback('buyUpgrade', { id });
}

function doDeposit() {
    const input = document.getElementById('deposit-amount');
    const amount = parseInt(input.value);
    if (!amount || amount <= 0) return;
    nuiCallback('deposit', { amount }).then(() => { input.value = ''; });
}

function doWithdraw() {
    const input = document.getElementById('withdraw-amount');
    const amount = parseInt(input.value);
    if (!amount || amount <= 0) return;
    nuiCallback('withdraw', { amount }).then(() => { input.value = ''; });
}

function closeUI() {
    nuiCallback('closeUI');
    document.body.style.display = 'none';
}

// ════════════════════ PARTICLES ════════════════════

function spawnParticle(e, amount) {
    const container = document.getElementById('click-particles');
    if (!container) return;
    const rect = container.getBoundingClientRect();
    const p = document.createElement('div');
    p.className = 'click-particle';
    p.textContent = `+${amount} 📦`;
    const x = (e.clientX - 25 || rect.left + rect.width / 2) - rect.left + (Math.random() * 40 - 20);
    const y = (e.clientY + 210 || rect.top + rect.height / 2) - rect.top;
    p.style.left = x + 'px';
    p.style.top = y + 'px';
    container.appendChild(p);
    setTimeout(() => p.remove(), 900);
}

// ════════════════════ ACTIVITY LOG ════════════════════

function addLog(type, text) {
    const icons = {
        order:    { icon: 'fa-solid fa-truck-ramp-box', color: 'bg-warning' },
        material: { icon: 'fa-solid fa-cubes',          color: 'bg-success' },
        delivery: { icon: 'fa-solid fa-truck-fast',     color: 'bg-info'    },
        upgrade:  { icon: 'fa-solid fa-arrow-up',       color: 'bg-primary' },
        system:   { icon: 'fa-solid fa-circle-info',    color: 'bg-secondary' },
    };
    const cfg = icons[type] || icons.system;
    const time = new Date().toLocaleTimeString([], { hour: '2-digit', minute: '2-digit', second: '2-digit' });
    activityLog.unshift({ text, time, cfg });
    if (activityLog.length > MAX_LOG) activityLog.pop();
    renderActivityFeed();
}

function renderActivityFeed() {
    const el = document.getElementById('activity-feed');
    if (!el) return;
    if (!activityLog.length) {
        el.innerHTML = '<div class="item p-3 text-center text-muted"><i class="fa-solid fa-clipboard me-1"></i> Start by ordering materials!</div>';
        return;
    }
    el.innerHTML = activityLog.map(a => `
        <div class="item p-3">
            <div class="row gx-2 align-items-center">
                <div class="col-auto"><div class="activity-icon ${a.cfg.color} text-white"><i class="${a.cfg.icon}"></i></div></div>
                <div class="col">
                    <div class="desc">${a.text}</div>
                    <div class="meta">${a.time}</div>
                </div>
            </div>
        </div>`).join('');
}

// ════════════════════ UI UPDATE ════════════════════

function updateUI() {
    if (!G || !CFG.STORAGE_PER_UPGRADE) return;

    const cap = getCapacity();
    const fillPct = cap > 0 ? Math.min(100, (G.boxes / cap) * 100) : 0;
    const boxVal = getBoxValue();

    // Header badges
    const hdrCash = document.getElementById('hdr-cash');
    if (hdrCash) hdrCash.textContent = fmt$(playerCash).replace('$', '');
    document.getElementById('hdr-money').textContent = fmt$(G.money).replace('$', '');
    document.getElementById('hdr-boxes').textContent = fmtN(G.boxes);
    document.getElementById('hdr-materials').textContent = fmtN(G.materials);

    // Nav badges
    document.getElementById('nav-pending-orders').textContent = (G.incomingOrders || []).length;
    document.getElementById('nav-active-deliveries').textContent = (G.activeDeliveries || []).length;

    // Dashboard stats
    document.getElementById('stat-money').textContent = fmt$(G.money);
    document.getElementById('stat-income').innerHTML = `<i class="fa-solid fa-arrow-up me-1"></i>${fmt$(boxVal)}/box`;
    document.getElementById('stat-materials').textContent = fmtN(G.materials);
    document.getElementById('stat-orders-pending').textContent = `${(G.incomingOrders || []).length} incoming`;
    document.getElementById('stat-boxes').textContent = `${fmtN(G.boxes)} / ${fmtN(cap)}`;
    document.getElementById('stat-box-value').textContent = `Value: ${fmt$(G.boxes * boxVal)}`;
    document.getElementById('stat-deliveries').textContent = G.stats.totalDeliveries || 0;
    document.getElementById('stat-deliveries-active').textContent = `${(G.activeDeliveries || []).length} active`;

    // Warehouse balance
    const balEl = document.getElementById('warehouse-balance');
    if (balEl) balEl.textContent = fmt$(G.money);

    // Pipeline
    document.getElementById('pipe-materials').textContent = `${fmtN(G.materials)} in stock`;
    document.getElementById('pipe-click').textContent = `${getClickPower()} boxes/click`;
    document.getElementById('pipe-stored').textContent = `${fmtN(G.boxes)} / ${fmtN(cap)}`;
    document.getElementById('pipe-deliver').textContent = `${fmt$(G.stats.totalMoneyEarned || 0)} earned`;

    // Materials tab
    const matStock = document.getElementById('mat-stock');
    if (matStock) matStock.textContent = fmtN(G.materials);
    const matIncoming = document.getElementById('mat-incoming-count');
    if (matIncoming) matIncoming.textContent = (G.incomingOrders || []).length;
    const matBalance = document.getElementById('mat-balance');
    if (matBalance) matBalance.textContent = fmt$(G.money).replace('$', '');

    renderIncomingOrders();

    // Packaging tab
    const pkgMat = document.getElementById('pkg-materials');
    if (pkgMat) pkgMat.textContent = fmtN(G.materials);
    const pkgCost = document.getElementById('pkg-cost');
    if (pkgCost) pkgCost.textContent = getMatPerBox();
    const pkgBoxes = document.getElementById('pkg-boxes');
    if (pkgBoxes) pkgBoxes.textContent = `${fmtN(G.boxes)} / ${fmtN(cap)}`;
    const pkgPow = document.getElementById('pkg-click-power');
    if (pkgPow) pkgPow.textContent = getClickPower();

    // Click button state
    const clickBtn = document.getElementById('main-click-btn');
    const canClick = G.materials >= getMatPerBox() && G.boxes < cap;
    clickBtn.disabled = !canClick;
    const preview = document.getElementById('click-preview');
    if (!canClick && G.materials < getMatPerBox()) {
        preview.textContent = '⚠️ Need materials! Go to Materials tab';
    } else if (!canClick) {
        preview.textContent = '⚠️ Warehouse full! Send a delivery';
    } else {
        preview.innerHTML = `+${getClickPower()} box(es) per click</br>Uses ${getMatPerBox()} materials per box`;
    }

    // Storage bar
    document.getElementById('storage-text').textContent = `${fmtN(G.boxes)} / ${fmtN(cap)}`;
    const bar = document.getElementById('storage-bar');
    bar.style.width = fillPct + '%';
    bar.textContent = Math.floor(fillPct) + '%';
    bar.className = 'progress-bar progress-bar-striped progress-bar-animated ' +
        (fillPct > 90 ? 'bg-danger' : fillPct > 60 ? 'bg-warning' : 'bg-primary');

    const hint = document.getElementById('storage-hint');
    if (fillPct >= 100) {
        hint.innerHTML = (G.upgrades.auto_deliver || 0) > 0
            ? '<span class="auto-badge active"><i class="fa-solid fa-robot"></i> Auto-deliver active</span>'
            : '⚠️ Warehouse full! Send deliveries to make room.';
    } else if ((G.upgrades.auto_pack || 0) > 0 && G.materials >= getMatPerBox()) {
        hint.innerHTML = `<span class="auto-badge active"><i class="fa-solid fa-robot"></i> Auto-packing ${getAutoPackRate()} box/s</span>`;
    } else {
        hint.textContent = 'Pack boxes then deliver them for profit!';
    }

    // Combo display (only update if not actively clicking — combo is set in doClick)
    const comboEl = document.getElementById('display-combo');
    if (comboEl && comboCount <= 0) comboEl.textContent = 'x0';
    const bpcEl = document.getElementById('display-bpc');
    if (bpcEl) bpcEl.textContent = getClickPower();
    const bvEl = document.getElementById('display-box-value');
    if (bvEl) bvEl.textContent = fmt$(boxVal);

    // Deliveries tab
    const delBoxes = document.getElementById('del-boxes');
    if (delBoxes) delBoxes.textContent = fmtN(G.boxes);
    const delActive = document.getElementById('del-active');
    if (delActive) delActive.textContent = (G.activeDeliveries || []).length;
    const delSlots = document.getElementById('del-slots');
    if (delSlots) delSlots.textContent = getMaxDeliveries();
    const delBV = document.getElementById('del-box-value');
    if (delBV) delBV.textContent = fmt$(boxVal);

    renderActiveDeliveries();
    const adb = document.getElementById('active-del-badge');
    if (adb) adb.textContent = `${(G.activeDeliveries || []).length} en route`;
    const icb = document.getElementById('incoming-count-badge');
    if (icb) icb.textContent = `${(G.incomingOrders || []).length} active`;

    // Enable/disable buttons
    document.querySelectorAll('.order-btn').forEach(btn => {
        btn.disabled = G.money < CFG.BASE_ORDER_COST;
    });
    const sendAllBtn = document.getElementById('send-all-btn');
    if (sendAllBtn) sendAllBtn.disabled = G.boxes <= 0 || (G.activeDeliveries || []).length >= getMaxDeliveries();
    const manualBtn = document.getElementById('manual-deliver-btn');
    if (manualBtn) manualBtn.disabled = G.boxes <= 0;

    // Delivery previews
    const delPreview = document.getElementById('delivery-preview');
    if (delPreview && G.boxes > 0) {
        const payout = getDeliveryPayout(G.boxes);
        const time = getDeliveryTime(G.boxes);
        const bonusPct = Math.round(getDeliveryBonusMult(G.boxes) * 100);
        delPreview.innerHTML = `
            <div class="row g-2 text-center">
                <div class="col-4"><div class="small text-muted">Payout</div><div class="fw-bold text-success">${fmt$(payout)}</div></div>
                <div class="col-4"><div class="small text-muted">Time</div><div class="fw-bold text-warning">${fmtTime(time)}</div></div>
                <div class="col-4"><div class="small text-muted">Volume Bonus</div><div class="fw-bold text-info">+${bonusPct}%</div></div>
            </div>`;
    } else if (delPreview) {
        delPreview.innerHTML = '<div class="text-center text-muted small">No boxes to deliver</div>';
    }

    const manualPreview = document.getElementById('manual-preview');
    if (manualPreview && G.boxes > 0) {
        const mPayout = getManualPayout(G.boxes);
        const mBonusPct = Math.round(getManualBonusMult(G.boxes) * 100);
        manualPreview.innerHTML = `
            <div class="row g-2 text-center">
                <div class="col-6"><div class="small text-muted">Payout</div><div class="fw-bold text-success">${fmt$(mPayout)}</div></div>
                <div class="col-6"><div class="small text-muted">Volume Bonus</div><div class="fw-bold text-info">+${mBonusPct}%</div></div>
            </div>`;
    } else if (manualPreview) {
        manualPreview.innerHTML = '<div class="text-center text-muted small">No boxes to sell</div>';
    }

    // Upgrade re-render on state change (level or money)
    const snap = JSON.stringify(G.upgrades) + '|' + Math.floor(G.money);
    if (snap !== _lastUpgradeSnap) {
        _lastUpgradeSnap = snap;
        renderUpgrades();
    }

    // Upgrade buttons
    document.querySelectorAll('.upgrade-btn').forEach(btn => {
        if (btn.classList.contains('btn-maxed')) return;
        btn.disabled = G.money < parseFloat(btn.dataset.cost);
    });

    renderStats();
}

// ── Incoming orders list ──
function renderIncomingOrders() {
    const el = document.getElementById('incoming-orders-list');
    if (!el || !G) return;
    const orders = G.incomingOrders || [];
    if (!orders.length) {
        el.innerHTML = '<div class="p-4 text-center text-muted"><i class="fa-solid fa-inbox me-1"></i> No incoming orders. Place an order above!</div>';
        return;
    }
    el.innerHTML = orders.map(o => {
        const pct = Math.max(0, Math.min(100, ((o.timeTotal - o.timeLeft) / o.timeTotal) * 100));
        return `
        <div class="timer-item">
            <div class="d-flex align-items-center gap-3">
                <div class="timer-icon ${o.color} text-white"><i class="${o.icon}"></i></div>
                <div class="flex-grow-1">
                    <div class="d-flex justify-content-between mb-1">
                        <span class="fw-bold">${o.type}</span>
                        <span class="timer-text">${fmtTime(o.timeLeft)} left</span>
                    </div>
                    <div class="progress timer-bar"><div class="progress-bar bg-warning" style="width:${pct}%"></div></div>
                    <div class="timer-text mt-1">+${o.amount} materials incoming</div>
                </div>
            </div>
        </div>`;
    }).join('');
}

// ── Active deliveries list ──
function renderActiveDeliveries() {
    const el = document.getElementById('active-deliveries-list');
    if (!el || !G) return;
    const deliveries = G.activeDeliveries || [];
    if (!deliveries.length) {
        el.innerHTML = '<div class="p-4 text-center text-muted"><i class="fa-solid fa-truck me-1"></i> No active deliveries. Send some boxes!</div>';
        return;
    }
    el.innerHTML = deliveries.map(d => {
        const pct = Math.max(0, Math.min(100, ((d.timeTotal - d.timeLeft) / d.timeTotal) * 100));
        return `
        <div class="timer-item">
            <div class="d-flex align-items-center gap-3">
                <div class="timer-icon ${d.color} text-white"><i class="${d.icon}"></i></div>
                <div class="flex-grow-1">
                    <div class="d-flex justify-content-between mb-1">
                        <span class="fw-bold">${d.type}</span>
                        <span class="timer-text">${fmtTime(d.timeLeft)} left</span>
                    </div>
                    <div class="progress timer-bar"><div class="progress-bar bg-info" style="width:${pct}%"></div></div>
                    <div class="d-flex justify-content-between timer-text mt-1">
                        <span>${d.boxes} boxes</span>
                        <span class="text-success fw-bold">+${fmt$(d.payout)}</span>
                    </div>
                </div>
            </div>
        </div>`;
    }).join('');
}

// ════════════════════ RENDERS ════════════════════

function renderMaterialOrders() {
    const grid = document.getElementById('material-orders-grid');
    if (!grid || !G) return;
    const amount = getOrderAmount();
    const time = CFG.BASE_ORDER_TIME * getOrderSpeedMult();
    grid.innerHTML = `
        <div class="col-12 col-md-8 col-lg-6 mx-auto">
            <div class="order-card shadow-sm p-4 text-center" onclick="orderMaterials()">
                <div class="order-icon ${MAT_ORDER.color || 'bg-info'} text-white mx-auto mb-2"><i class="${MAT_ORDER.icon || 'fa-solid fa-truck-ramp-box'}"></i></div>
                <div class="fw-bold fs-5">${MAT_ORDER.name || 'Supply Shipment'}</div>
                <div class="text-muted mb-2">${fmtN(amount)} materials in ${fmtTime(time)}</div>
                <button class="btn-game order-btn" data-cost="${CFG.BASE_ORDER_COST}" ${G.money < CFG.BASE_ORDER_COST ? 'disabled' : ''}>
                    <i class="fa-solid fa-cart-shopping me-1"></i>${fmt$(CFG.BASE_ORDER_COST)}
                </button>
            </div>
        </div>`;
}

function renderDeliveryOptions() {
    const grid = document.getElementById('delivery-options-grid');
    if (!grid || !G) return;
    const cap = getCapacity();
    const maxBonus = Math.round(getDeliveryBonusMult(cap) * 100);
    const maxManualBonus = Math.round(getManualBonusMult(cap) * 100);
    grid.innerHTML = `
        <div class="col-md-6">
            <div class="app-card shadow-sm p-4 text-center h-100">
                <div class="mb-3"><i class="fa-solid fa-truck-fast fs-1 text-info"></i></div>
                <h4 class="fw-bold mb-2">Send All Boxes</h4>
                <p class="text-muted mb-3">Deliver all boxes via truck. Volume bonus up to <strong>+${maxBonus}%</strong> at full capacity. Uses a delivery slot.</p>
                <div class="mb-3" id="delivery-preview"><div class="text-center text-muted small">No boxes to deliver</div></div>
                <button id="send-all-btn" class="btn-game btn-lg" onclick="sendAllBoxes()" disabled>
                    <i class="fa-solid fa-paper-plane me-2"></i>Send Delivery
                </button>
                <div class="mt-3">
                    <div class="d-flex justify-content-center gap-3 small text-muted">
                        <span><i class="fa-solid fa-clock me-1"></i>Base: ${fmtTime(CFG.BASE_DELIVERY_TIME)} + ${CFG.DELIVERY_TIME_PER_BOX}s/box</span>
                        <span><i class="fa-solid fa-gauge-high me-1"></i>${getMaxDeliveries()} slot(s)</span>
                    </div>
                </div>
            </div>
        </div>
        <div class="col-md-6">
            <div class="app-card shadow-sm p-4 text-center h-100 border-warning">
                <div class="mb-3"><i class="fa-solid fa-truck fs-1 text-warning"></i></div>
                <h4 class="fw-bold mb-2">Manual Delivery</h4>
                <p class="text-muted mb-3">Drive the delivery yourself for a <strong>better</strong> cash bonus — up to <strong>+${maxManualBonus}%</strong>! Does not use a delivery slot.</p>
                <div class="mb-3" id="manual-preview"><div class="text-center text-muted small">No boxes to sell</div></div>
                <button id="manual-deliver-btn" class="btn-game btn-lg btn-warning" onclick="manualDeliver()" disabled>
                    <i class="fa-solid fa-truck me-2"></i>Start Delivery
                </button>
                <div class="mt-3">
                    <div class="d-flex justify-content-center gap-3 small text-muted">
                        <span><i class="fa-solid fa-truck me-1"></i>Drive to destination</span>
                        <span><i class="fa-solid fa-arrow-up me-1"></i>+${maxManualBonus}% max bonus</span>
                    </div>
                </div>
            </div>
        </div>`;
}

function renderUpgrades() {
    if (!G || !UPGRADES.length) return;
    const categories = { packaging: 'upgrades-packaging', warehouse: 'upgrades-warehouse', delivery: 'upgrades-delivery', automation: 'upgrades-automation' };

    Object.entries(categories).forEach(([cat, elId]) => {
        const el = document.getElementById(elId);
        if (!el) return;
        const items = UPGRADES.filter(u => u.cat === cat);
        el.innerHTML = items.map(u => {
            const level = G.upgrades[u.id] || 0;
            const maxed = level >= u.max;
            const cost = maxed ? 0 : getUpgradeCost(u.id);
            const canBuy = !maxed && G.money >= cost;

            let autoTag = '';
            if ((u.id === 'auto_order' || u.id === 'auto_deliver' || u.id === 'auto_pack') && level > 0) {
                autoTag = ` <span class="auto-badge active"><i class="fa-solid fa-robot"></i> Active</span>`;
            }

            let effect = '';
            switch (u.id) {
                case 'click_power':    effect = `${CFG.INITIAL_CLICK_POWER + level} boxes/click`; break;
                case 'mat_efficiency': effect = `${Math.max(1, CFG.MAT_BASE_COST - level)} mats/box`; break;
                case 'auto_pack':      effect = `${level} boxes/s`; break;
                case 'storage':        effect = `${CFG.INITIAL_CAPACITY + level * CFG.STORAGE_PER_UPGRADE} capacity`; break;
                case 'box_value':      effect = `$${CFG.BOX_BASE_VALUE + level * CFG.BOX_VALUE_PER_UPGRADE}/box`; break;
                case 'del_slots':      effect = `${CFG.INITIAL_DELIVERY_SLOTS + level} slots`; break;
                case 'del_speed':      effect = `${Math.round((1 - Math.pow(CFG.DELIVERY_SPEED_FACTOR, level)) * 100)}% faster`; break;
                case 'order_speed':    effect = `${Math.round((1 - Math.pow(CFG.ORDER_SPEED_FACTOR, level)) * 100)}% faster`; break;
                case 'order_capacity': effect = `${getOrderAmount()} mats/order`; break;
                case 'auto_order':     effect = level > 0 ? `Active (${fmtN(getOrderAmount())} mats)` : 'Inactive'; break;
                case 'auto_deliver':   effect = level > 0 ? 'Active (best option)' : 'Inactive'; break;
                default:               effect = `Lv ${level}`;
            }

            return `
            <div class="col-12 col-md-6 col-xl-4">
                <div class="upgrade-card shadow-sm p-3">
                    <div class="d-flex align-items-start mb-2">
                        <div class="upgrade-icon ${u.color} text-white me-3"><i class="${u.icon}"></i></div>
                        <div class="flex-grow-1">
                            <div class="upgrade-level text-muted">Lv ${level} / ${u.max}${autoTag}</div>
                            <div class="upgrade-name">${u.name}</div>
                            <div class="upgrade-desc">${u.desc}</div>
                        </div>
                    </div>
                    <div class="d-flex justify-content-between align-items-center mt-2">
                        <div class="upgrade-effect"><i class="fa-solid fa-bolt me-1"></i>${effect}</div>
                        <button class="btn-game upgrade-btn ${maxed ? 'btn-maxed' : ''}"
                                data-cost="${cost}"
                                ${maxed ? 'disabled' : (canBuy ? '' : 'disabled')}
                                onclick="buyUpgrade('${u.id}')">
                            ${maxed ? 'MAX' : fmt$(cost)}
                        </button>
                    </div>
                    <div class="progress mt-2" style="height: 4px;">
                        <div class="progress-bar ${u.color}" style="width: ${(level / u.max) * 100}%"></div>
                    </div>
                </div>
            </div>`;
        }).join('');
    });
}

function renderStats() {
    if (!G) return;
    const el = document.getElementById('stats-general');
    if (!el) return;
    const rows = [
        ['Total Clicks',     fmtN(G.stats.totalClicks || 0)],
        ['Boxes Packed',      fmtN(G.stats.totalBoxesPacked || 0)],
        ['Boxes Delivered',   fmtN(G.stats.totalBoxesDelivered || 0)],
        ['Deliveries Made',   G.stats.totalDeliveries || 0],
        ['Money Earned',      fmt$(G.stats.totalMoneyEarned || 0)],
        ['Money Spent',       fmt$(G.stats.totalMoneySpent || 0)],
        ['Materials Ordered', fmtN(G.stats.totalMaterialsOrdered || 0)],
        ['Play Time',         fmtTime(G.stats.playTime || 0)],
    ];
    el.innerHTML = rows.map(([l, v]) => `<tr><td class="stat-label">${l}</td><td class="stat-value">${v}</td></tr>`).join('');

    const el2 = document.getElementById('stats-upgrades');
    if (!el2) return;
    el2.innerHTML = UPGRADES.map(u => `
        <tr>
            <td class="stat-label"><i class="${u.icon} me-2 ${u.color.replace('bg-', 'text-')}"></i>${u.name}</td>
            <td class="stat-value">Lv ${G.upgrades[u.id] || 0} / ${u.max}</td>
        </tr>`).join('');
}

// ════════════════════ TOASTS ════════════════════

function showToast(title, body, type) {
    const container = document.getElementById('toast-container');
    if (!container) return;
    const colors = { primary: 'text-bg-primary', success: 'text-bg-success', warning: 'text-bg-warning', danger: 'text-bg-danger', info: 'text-bg-info' };
    const t = document.createElement('div');
    t.className = `toast game-toast show ${colors[type] || ''}`;
    t.setAttribute('role', 'alert');
    t.innerHTML = `
        <div class="toast-header">
            <strong class="me-auto">${title}</strong>
            <button type="button" class="btn-close btn-close-white" data-bs-dismiss="toast"></button>
        </div>
        <div class="toast-body">${body}</div>`;
    container.appendChild(t);
    setTimeout(() => { t.classList.remove('show'); setTimeout(() => t.remove(), 300); }, 4000);
    t.querySelector('.btn-close').addEventListener('click', () => { t.classList.remove('show'); setTimeout(() => t.remove(), 300); });
}

// ════════════════════ TABS ════════════════════

function switchTab(name) {
    document.querySelectorAll('.tab-panel').forEach(p => p.classList.remove('active'));
    document.querySelectorAll('.app-nav-main .nav-link').forEach(l => l.classList.remove('active'));
    const panel = document.getElementById('tab-' + name);
    if (panel) panel.classList.add('active');
    const link = document.querySelector(`.nav-link[data-tab="${name}"]`);
    if (link) link.classList.add('active');

    if (name === 'materials')  renderMaterialOrders();
    if (name === 'deliveries') renderDeliveryOptions();
    if (name === 'upgrades')   renderUpgrades();
    if (name === 'stats')      renderStats();

    if (window.innerWidth < 1200) {
        document.getElementById('app-sidepanel').classList.remove('sidepanel-visible');
    }
}

// ════════════════════ SIDE PANEL ════════════════════

function setupSidePanel() {
    const toggler = document.getElementById('sidepanel-toggler');
    const panel = document.getElementById('app-sidepanel');
    const close = document.getElementById('sidepanel-close');
    const drop = document.getElementById('sidepanel-drop');

    function responsive() {
        if (window.innerWidth >= 1200) {
            panel.classList.remove('sidepanel-hidden');
            panel.classList.add('sidepanel-visible');
        } else {
            panel.classList.remove('sidepanel-visible');
            panel.classList.add('sidepanel-hidden');
        }
    }
    window.addEventListener('load', responsive);
    window.addEventListener('resize', responsive);

    toggler.addEventListener('click', e => { e.preventDefault(); panel.classList.toggle('sidepanel-visible'); panel.classList.toggle('sidepanel-hidden'); });
    close.addEventListener('click', e => { e.preventDefault(); panel.classList.remove('sidepanel-visible'); panel.classList.add('sidepanel-hidden'); });
    drop.addEventListener('click', () => { panel.classList.remove('sidepanel-visible'); panel.classList.add('sidepanel-hidden'); });
}

// ════════════════════ INIT ════════════════════

function init() {
    setupSidePanel();

    document.querySelectorAll('.nav-link[data-tab]').forEach(link => {
        link.addEventListener('click', e => { e.preventDefault(); switchTab(link.dataset.tab); });
    });

    document.getElementById('main-click-btn').addEventListener('click', doClick);

    document.addEventListener('keydown', e => {
        if (e.key === 'Escape') { e.preventDefault(); closeUI(); return; }
        if (e.key === ' ' || e.key === 'Enter') {
            e.preventDefault();
            const activePanel = document.querySelector('.tab-panel.active');
            if (activePanel && activePanel.id === 'tab-packaging') doClick({ clientX: 0, clientY: 0 });
        }
    });

    const depBtn = document.getElementById('deposit-btn');
    if (depBtn) depBtn.addEventListener('click', doDeposit);
    const wdBtn = document.getElementById('withdraw-btn');
    if (wdBtn) wdBtn.addEventListener('click', doWithdraw);
    const closeBtn = document.getElementById('close-ui-btn');
    if (closeBtn) closeBtn.addEventListener('click', closeUI);

    console.log('🏭 Warehouse Empire NUI initialized');
}

document.addEventListener('DOMContentLoaded', init);
