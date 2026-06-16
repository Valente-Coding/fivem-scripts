window.addEventListener('message', function(event) {
    var data = event.data;

    if (data.type === 'showUI') {
        document.getElementById('fishing-stats').classList.remove('hidden');
        if (data.stats) updateStats(data.stats);
    }
    if (data.type === 'hideUI') {
        document.getElementById('fishing-stats').classList.add('hidden');
    }
    if (data.type === 'updateStats') {
        updateStats(data.stats);
    }
    if (data.type === 'showLastCatch') {
        var el = document.getElementById('last-catch');
        el.textContent = '$' + data.amount;
        el.style.color = '#00ff00';
        setTimeout(function() { el.style.color = '#1e90ff'; }, 1000);
    }
});

function updateStats(stats) {
    document.getElementById('current-session').textContent = stats.sessionCaught + ' fish';
    document.getElementById('session-earnings').textContent = '$' + stats.sessionEarned;
    document.getElementById('total-fish').textContent = stats.totalCaught + ' fish';
    document.getElementById('total-earnings').textContent = '$' + stats.totalEarned;
}
