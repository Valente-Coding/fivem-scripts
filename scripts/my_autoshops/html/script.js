window.addEventListener('message', function(event) {
    var data = event.data;
    if (data.type === 'openRepair') {
        document.getElementById('repair-menu').classList.remove('hidden');
        var damagePercent = data.damage || 0;
        var price = data.price || 0;
        var oilLevel = data.oilLevel != null ? data.oilLevel : 100;
        var oilPrice = data.oilPrice || 0;
        var needsRepair = data.needsRepair;

        // Damage bar
        var fill = document.getElementById('damage-percentage');
        fill.style.width = damagePercent + '%';
        document.getElementById('damage-text').textContent = damagePercent;
        document.getElementById('repair-cost').textContent = price.toLocaleString();

        if (damagePercent < 30) {
            fill.style.background = 'linear-gradient(to right, #2ecc71, #27ae60)';
        } else if (damagePercent < 70) {
            fill.style.background = 'linear-gradient(to right, #f39c12, #e67e22)';
        } else {
            fill.style.background = 'linear-gradient(to right, #ff9a00, #ff4d4d)';
        }

        // Oil bar
        var oilFill = document.getElementById('oil-percentage');
        oilFill.style.width = oilLevel + '%';
        document.getElementById('oil-text').textContent = oilLevel;
        document.getElementById('oil-cost').textContent = oilPrice.toLocaleString();

        if (oilLevel > 50) {
            oilFill.style.background = 'linear-gradient(to right, #2ecc71, #27ae60)';
        } else if (oilLevel > 25) {
            oilFill.style.background = 'linear-gradient(to right, #f39c12, #e67e22)';
        } else {
            oilFill.style.background = 'linear-gradient(to right, #ff9a00, #ff4d4d)';
        }

        // Show/hide repair button based on damage
        var repairBtn = document.getElementById('confirm-repair');
        if (needsRepair) {
            repairBtn.classList.remove('disabled-btn');
            repairBtn.disabled = false;
        } else {
            repairBtn.classList.add('disabled-btn');
            repairBtn.disabled = true;
        }

        // Show/hide oil change button based on oil level
        var oilBtn = document.getElementById('confirm-oil-change');
        if (oilLevel < 100) {
            oilBtn.classList.remove('disabled-btn');
            oilBtn.disabled = false;
        } else {
            oilBtn.classList.add('disabled-btn');
            oilBtn.disabled = true;
        }

        // Drop-off section (only when oil is depleted)
        var oilDepleted = data.oilDepleted || false;
        var dropOffSection = document.getElementById('dropoff-section');
        var dropOffBtn = document.getElementById('confirm-dropoff');

        if (oilDepleted) {
            dropOffSection.classList.remove('hidden');
            dropOffBtn.classList.remove('hidden');
            document.getElementById('dropoff-cost').textContent = (data.dropOffPrice || 0).toLocaleString();
            document.getElementById('dropoff-time').textContent = Math.ceil((data.dropOffTime || 300) / 60);
        } else {
            dropOffSection.classList.add('hidden');
            dropOffBtn.classList.add('hidden');
        }
    } else if (data.type === 'closeUI') {
        document.getElementById('repair-menu').classList.add('hidden');
    }
});

document.getElementById('close-menu').addEventListener('click', function() {
    fetch('https://my_autoshops/closeUI', { method: 'POST', body: JSON.stringify({}) });
});

document.getElementById('confirm-repair').addEventListener('click', function() {
    if (!this.disabled) {
        fetch('https://my_autoshops/repairVehicle', { method: 'POST', body: JSON.stringify({}) });
    }
});

document.getElementById('confirm-oil-change').addEventListener('click', function() {
    if (!this.disabled) {
        fetch('https://my_autoshops/oilChange', { method: 'POST', body: JSON.stringify({}) });
    }
});

document.getElementById('confirm-dropoff').addEventListener('click', function() {
    if (!this.disabled) {
        fetch('https://my_autoshops/dropOffVehicle', { method: 'POST', body: JSON.stringify({}) });
    }
});

document.addEventListener('keyup', function(e) {
    if (e.key === 'Escape') {
        fetch('https://my_autoshops/closeUI', { method: 'POST', body: JSON.stringify({}) });
    }
});
