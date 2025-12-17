// ========== HTML ESCAPING ==========
// Prevents XSS attacks by escaping HTML special characters
function escapeHtml(text) {
    const div = document.createElement('div');
    div.textContent = text;
    return div.innerHTML;
}

// ========== TIME FORMATTING ==========
// Formats seconds to HH:MM:SS format
// Example: 3661 seconds -> "01:01:01"
function formatTime(seconds) {
    const hours = Math.floor(seconds / 3600);
    const minutes = Math.floor((seconds % 3600) / 60);
    const secs = seconds % 60;

    const pad = (num) => num.toString().padStart(2, '0');
    return `${pad(hours)}:${pad(minutes)}:${pad(secs)}`;
}

// Formats minutes to readable duration (Xh Ym)
// Example: 125 minutes -> "2h 5m"
function formatDuration(minutes) {
    if (!minutes || minutes === 0) return "0m";

    const hours = Math.floor(minutes / 60);
    const mins = minutes % 60;

    if (hours === 0) return `${mins}m`;
    if (mins === 0) return `${hours}h`;
    return `${hours}h ${mins}m`;
}

// ========== DATE FORMATTING ==========
// Formats date string to "Today", "Yesterday", or formatted date
// Example: Today's date -> "Today, 14:30"
function formatSessionDate(dateString) {
    const date = new Date(dateString);
    const now = new Date();
    const today = new Date(now.getFullYear(), now.getMonth(), now.getDate());
    const yesterday = new Date(today);
    yesterday.setDate(yesterday.getDate() - 1);

    const sessionDate = new Date(date.getFullYear(), date.getMonth(), date.getDate());

    const timeStr = date.toLocaleTimeString('en-US', {
        hour: '2-digit',
        minute: '2-digit',
        hour12: false
    });

    if (sessionDate.getTime() === today.getTime()) {
        return `Today, ${timeStr}`;
    } else if (sessionDate.getTime() === yesterday.getTime()) {
        return `Yesterday, ${timeStr}`;
    } else {
        return date.toLocaleDateString('en-US', {
            month: 'short',
            day: 'numeric',
            year: 'numeric'
        });
    }
}

// ========== CONSTANTS ==========
// Task status mapping for UI display
const STATUS_MAP = {
    'pending': { class: 'warn', text: 'Pending' },
    'in_progress': { class: 'info', text: 'In Progress' },
    'completed': { class: 'done', text: 'Completed' }
};

// Task priority mapping for UI display
const PRIORITY_MAP = {
    'low': 'Low',
    'normal': 'Normal',
    'high': 'High'
};
