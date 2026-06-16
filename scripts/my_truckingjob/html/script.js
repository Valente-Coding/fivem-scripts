const jobMenu = document.getElementById('job-menu');
const jobHud = document.getElementById('job-hud');

window.addEventListener('message', (event) => {
    const d = event.data;
    if (d.type === 'openMenu') {
        document.getElementById('menuLevel').textContent = d.maxLevel ? 'MAX' : d.level;
        document.getElementById('menuJobs').textContent = d.jobsDone;
        document.getElementById('menuDeliveries').textContent = d.deliveriesDone || 0;
        document.getElementById('menuEarnings').textContent = '$' + (d.totalEarnings || 0).toLocaleString();
        document.getElementById('menuNextLevel').textContent = d.maxLevel ? 'MAX' : (d.nextLevelJobs + ' jobs');
        document.getElementById('menuDailyJobs').textContent = (d.dailyJobsCount || 0) + '/' + d.maxDailyJobs;

        const startBtn = document.getElementById('startBtn');
        if ((d.dailyJobsCount || 0) >= d.maxDailyJobs) {
            startBtn.disabled = true;
            startBtn.textContent = 'DAILY LIMIT REACHED';
        } else {
            startBtn.disabled = false;
            startBtn.textContent = 'START TRUCKING';
        }

        jobMenu.classList.remove('hidden');
    } else if (d.type === 'closeMenu') {
        jobMenu.classList.add('hidden');
    } else if (d.type === 'showHUD') {
        jobHud.classList.remove('hidden');
    } else if (d.type === 'hideHUD') {
        jobHud.classList.add('hidden');
    } else if (d.type === 'updateHUD') {
        document.getElementById('hudLevel').textContent = d.maxLevel ? 'MAX' : d.level;
        document.getElementById('hudTimer').textContent = d.timeLeft;
        document.getElementById('hudNextLevel').textContent = d.maxLevel ? 'MAX' : (d.nextLevelJobs + ' jobs');
    }
});

document.getElementById('startBtn').addEventListener('click', () => {
    fetch(`https://${GetParentResourceName()}/startJob`, {
        method: 'POST', headers: {'Content-Type': 'application/json'}, body: JSON.stringify({})
    });
});

document.getElementById('menuCloseBtn').addEventListener('click', () => {
    fetch(`https://${GetParentResourceName()}/closeMenu`, {
        method: 'POST', headers: {'Content-Type': 'application/json'}, body: JSON.stringify({})
    });
});

document.addEventListener('keydown', (e) => {
    if (e.key === 'Escape' && !jobMenu.classList.contains('hidden')) {
        fetch(`https://${GetParentResourceName()}/closeMenu`, {
            method: 'POST', headers: {'Content-Type': 'application/json'}, body: JSON.stringify({})
        });
    }
});
