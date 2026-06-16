window.addEventListener('message', function(event) {
    if (event.data.type === 'updateTime') {
        const dayCountDisplay = document.getElementById('day-count-display');
        const dayDisplay = document.getElementById('day-display');
        const timeDisplay = document.getElementById('time-display');
        
        if (dayCountDisplay && dayDisplay && timeDisplay) {
            dayCountDisplay.textContent = 'Day ' + event.data.daysPassed;
            dayDisplay.textContent = event.data.day;
            timeDisplay.textContent = event.data.hour + ':' + event.data.minute;
        }
    }
});
