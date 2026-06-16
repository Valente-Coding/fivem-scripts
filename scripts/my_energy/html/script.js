window.addEventListener('message', function(event) {
    if (event.data.action === 'updateEnergy') {
        const energy = event.data.energy;
        const maxEnergy = event.data.maxEnergy || 100;
        const percent = Math.max(0, Math.min(100, (energy / maxEnergy) * 100));

        const fill = document.getElementById('energy-fill');
        if (fill) {
            fill.style.width = percent + '%';

            // Set color level
            if (percent > 50) {
                fill.setAttribute('data-level', 'high');
            } else if (percent > 20) {
                fill.setAttribute('data-level', 'medium');
            } else {
                fill.setAttribute('data-level', 'low');
            }
        }
    }
});
