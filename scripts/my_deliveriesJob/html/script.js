const jobMenu = document.getElementById('job-menu');
const jobHud = document.getElementById('job-hud');

window.addEventListener('message', (event) => {
    const data = event.data;

    if (data.type === 'openJobMenu') {
        document.getElementById('menuLevel').textContent = data.maxLevel ? 'MAX' : data.level;
        document.getElementById('menuJobs').textContent = data.jobsDone;
        document.getElementById('menuDeliveries').textContent = data.deliveriesDone;
        document.getElementById('menuEarnings').textContent = '$' + (data.totalEarnings || 0).toLocaleString();
        document.getElementById('menuNextLevel').textContent = data.maxLevel ? 'MAX' : (data.nextLevelJobs + ' jobs');
        document.getElementById('menuDailyJobs').textContent = (data.dailyJobsCount || 0) + '/' + data.maxDailyJobs;

        const startBtn = document.getElementById('startBtn');
        if ((data.dailyJobsCount || 0) >= data.maxDailyJobs) {
            startBtn.disabled = true;
            startBtn.textContent = 'DAILY LIMIT REACHED';
        } else {
            startBtn.disabled = false;
            startBtn.textContent = 'START JOB';
        }

        jobMenu.classList.remove('hidden');
    } else if (data.type === 'closeJobMenu') {
        jobMenu.classList.add('hidden');
    } else if (data.type === 'showUI') {
        jobHud.classList.remove('hidden');
    } else if (data.type === 'hideUI') {
        jobHud.classList.add('hidden');
    } else if (data.type === 'updateUI') {
        document.getElementById('hudLevel').textContent = data.maxLevel ? 'MAX' : data.level;
        document.getElementById('hudTimer').textContent = data.timeLeft;
        document.getElementById('hudDeliveries').textContent = data.deliveries + '/' + data.totalDeliveries;
        document.getElementById('hudNextLevel').textContent = data.maxLevel ? 'MAX' : (data.nextLevelJobs + ' jobs');
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
