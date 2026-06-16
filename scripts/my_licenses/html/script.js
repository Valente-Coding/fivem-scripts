(function() {
    let licenses = {};
    let currentLicenses = {};

    function formatMoney(amount) {
        return '$' + amount.toString().replace(/\B(?=(\d{3})+(?!\d))/g, ",");
    }

    function displayLicenseCenter() {
        const container = document.querySelector('.licenses-container');
        container.innerHTML = '';

        for (const [type, info] of Object.entries(licenses)) {
            const isOwned = currentLicenses[type] === true;
            container.innerHTML += createLicenseCard(type, info, isOwned);
        }

        const el = document.getElementById('license-center');
        el.style.display = 'flex';
    }

    function createLicenseCard(type, info, isOwned) {
        let buttonHtml = '';
        let badgeHtml = '';

        if (isOwned) {
            buttonHtml = '<button class="btn btn-owned" disabled>Already Owned</button>';
            badgeHtml = '<span class="status-badge badge-owned">OWNED</span>';
        } else {
            buttonHtml = `<button class="btn purchase-license" data-type="${type}">Purchase - ${formatMoney(info.price)}</button>`;
        }

        return `
            <div class="license-card">
                ${badgeHtml}
                <div class="license-content">
                    <div class="license-info">
                        <h3 class="license-title">${info.label}</h3>
                        <p class="license-description">${info.description}</p>
                        <div class="license-price">${formatMoney(info.price)}</div>
                    </div>
                    <div class="license-action">
                        ${buttonHtml}
                    </div>
                </div>
            </div>
        `;
    }

    function showNotification(message) {
        const el = document.getElementById('notification');
        document.getElementById('notification-message').textContent = message;
        el.style.display = 'block';
        el.classList.remove('fade-out');
        el.classList.add('fade-in');

        setTimeout(function() {
            el.classList.remove('fade-in');
            el.classList.add('fade-out');
            setTimeout(function() {
                el.style.display = 'none';
                el.classList.remove('fade-out');
            }, 300);
        }, 3000);
    }

    function closeLicenseCenter() {
        document.getElementById('license-center').style.display = 'none';
        fetch('https://my_licenses/close', { method: 'POST', body: JSON.stringify({}) });
    }

    window.addEventListener('message', function(event) {
        const data = event.data;
        if (data.type === 'openLicenseCenter') {
            licenses = data.licenses;
            currentLicenses = data.currentLicenses;
            displayLicenseCenter();
        } else if (data.type === 'closeLicenseCenter') {
            document.getElementById('license-center').style.display = 'none';
        }
    });

    document.getElementById('close-btn').addEventListener('click', closeLicenseCenter);

    document.addEventListener('keyup', function(e) {
        if (e.key === 'Escape') closeLicenseCenter();
    });

    document.addEventListener('click', function(e) {
        if (e.target.classList.contains('purchase-license')) {
            const licenseType = e.target.dataset.type;
            fetch('https://my_licenses/purchaseLicense', {
                method: 'POST',
                body: JSON.stringify({ license: licenseType })
            });
        }
    });
})();
