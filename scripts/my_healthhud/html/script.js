function updateHealth(percent) {
    const valueEl = document.getElementById('hud-health');
    const barEl = document.getElementById('hud-health-bar');
    const iconEl = document.querySelector('.health-icon');
    if (!valueEl || !barEl) return;

    valueEl.textContent = percent + '%';
    barEl.style.width = percent + '%';

    // Remove old color classes
    const level = percent > 60 ? 'high' : percent > 25 ? 'medium' : 'low';
    ['high', 'medium', 'low'].forEach(c => {
        valueEl.classList.remove(c);
        barEl.classList.remove(c);
    });
    valueEl.classList.add(level);
    barEl.classList.add(level);

    // Pulse heart icon when health is low
    if (iconEl) {
        if (level === 'low') {
            iconEl.classList.add('pulse');
        } else {
            iconEl.classList.remove('pulse');
        }
    }
}

window.addEventListener('message', (event) => {
    const data = event.data;
    if (!data || data.action !== 'updateHealth') return;
    updateHealth(data.health);
});
