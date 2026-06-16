const hud        = document.getElementById('hud');
const speedVal   = document.getElementById('speed-val');
const engineBar  = document.getElementById('engine-bar');
const enginePct  = document.getElementById('engine-pct');
const bodyBar    = document.getElementById('body-bar');
const bodyPct    = document.getElementById('body-pct');
const oilBar     = document.getElementById('oil-bar');
const oilPct     = document.getElementById('oil-pct');
const mileageEl  = document.getElementById('mileage-text');

const colors = {
    engine: { high: '#4ade80', medium: '#facc15', low: '#ef4444' },
    body:   { high: '#a78bfa', medium: '#facc15', low: '#ef4444' },
    oil:    { high: '#fb923c', medium: '#facc15', low: '#ef4444' }
};

function getLevel(pct) {
    return pct > 60 ? 'high' : pct > 25 ? 'medium' : 'low';
}

function applyBar(barEl, pctEl, percent, type) {
    var level = getLevel(percent);
    barEl.className = 'health-bar-fill ' + type + ' ' + level;
    barEl.style.width = percent + '%';
    pctEl.textContent  = percent + '%';
    pctEl.style.color  = colors[type][level];
}

window.addEventListener('message', function(event) {
    var d = event.data;

    if (d.type === 'show') {
        hud.classList.add('visible');
    }
    if (d.type === 'hide') {
        hud.classList.remove('visible');
    }
    if (d.type === 'update') {
        speedVal.textContent = d.speed;

        applyBar(engineBar, enginePct, d.health, 'engine');
        applyBar(bodyBar,   bodyPct,   d.body,   'body');
        applyBar(oilBar,    oilPct,    d.oil !== undefined ? d.oil : 100, 'oil');

        if (d.mileage && d.mileage > 0) {
            mileageEl.textContent = d.mileage.toFixed(1) + ' KM';
            mileageEl.classList.add('visible');
        } else {
            mileageEl.classList.remove('visible');
        }
    }
});
