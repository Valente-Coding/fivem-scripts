const app = document.getElementById('app');
const titleEl = document.getElementById('title');
const distanceLabel = document.getElementById('distance-label');
const fareLabel = document.getElementById('fare-label');
const waitLabel = document.getElementById('wait-label');
const distanceValue = document.getElementById('distance-value');
const fareValue = document.getElementById('fare-value');
const waitValue = document.getElementById('wait-value');

function show(data) {
    titleEl.textContent = data.title || 'Taxi Service';
    distanceLabel.textContent = data.distanceLabel || 'Distance';
    fareLabel.textContent = data.fareLabel || 'Fare';
    waitLabel.textContent = data.waitLabel || 'Estimated Wait';

    document.getElementById('confirm').textContent = 'Confirm Taxi';
    document.getElementById('cancel').textContent = data.cancel || 'Cancel';

    distanceValue.textContent = `${data.distance || 0} m`;
    fareValue.textContent = `$${data.fare || 0}`;
    waitValue.textContent = `${data.wait || 0} s`;

    app.classList.remove('hidden');
    app.style.display = 'flex';
}

function hide() {
    app.classList.add('hidden');
    app.style.display = 'none';
}

window.addEventListener('message', (event) => {
    const data = event.data || {};
    if (data.action === 'open') {
        show(data);
    } else if (data.action === 'close') {
        hide();
    }
});

window.addEventListener('keydown', (e) => {
    if (e.key === 'Escape') {
        send('cancel');
    }
});

function send(method) {
    fetch(`https://${GetParentResourceName()}/selectPayment`, {
        method: 'POST',
        headers: { 'Content-Type': 'application/json' },
        body: JSON.stringify({ method })
    });
}

document.getElementById('confirm').addEventListener('click', () => send('confirm'));
document.getElementById('cancel').addEventListener('click', () => send('cancel'));

hide();
