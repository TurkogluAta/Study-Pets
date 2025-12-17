// ========== GLOBAL STATE ==========
let sessionsData = [];
let currentSession = null;
let timerState = 'idle'; // 'idle', 'running', 'paused'
let elapsedSeconds = 0;
let timerInterval = null;

// ========== INITIALIZATION ==========
document.addEventListener('DOMContentLoaded', async () => {
    if (!requireAuth()) return;

    await loadSessions();
    setupEventListeners();
});

function setupEventListeners() {
    document.getElementById('startBtn').addEventListener('click', handleStartSession);
    document.getElementById('pauseBtn').addEventListener('click', handlePauseSession);
    document.getElementById('stopBtn').addEventListener('click', handleCompleteSession);

    // Focus rating buttons
    document.querySelectorAll('.rating-btn').forEach(btn => {
        btn.addEventListener('click', () => {
            const rating = parseInt(btn.dataset.rating);
            handleRatingSelection(rating);
        });
    });
}

// ========== DATA LOADING ==========
async function loadSessions() {
    try {
        const { data: sessions } = await api.get('/study_sessions');
        sessionsData = sessions;

        updateStatsCards(sessions);
        renderSessionHistory(sessions);
    } catch (error) {
        console.error('Load sessions error:', error);
    }
}

// ========== TIMER CORE FUNCTIONS ==========
function startTimerInterval() {
    timerInterval = setInterval(() => {
        elapsedSeconds++;
        updateTimerDisplay();
    }, 1000);
}

function stopTimerInterval() {
    if (timerInterval) {
        clearInterval(timerInterval);
        timerInterval = null;
    }
}

function updateTimerDisplay() {
    const display = document.getElementById('timerDisplay');
    const status = document.getElementById('timerStatus');

    if (display) {
        display.textContent = formatTime(elapsedSeconds);
    }

    if (status) {
        switch (timerState) {
            case 'idle':
                status.textContent = 'Ready to start';
                break;
            case 'running':
                status.textContent = 'Session in progress...';
                break;
            case 'paused':
                status.textContent = 'Paused';
                break;
        }
    }
}

// ========== TIMER EVENT HANDLERS ==========
async function handleStartSession() {
    const titleInput = document.getElementById('sessionTitle');
    const notesInput = document.getElementById('sessionNotes');
    const durationInput = document.getElementById('sessionDuration');

    const title = titleInput.value.trim();
    const notes = notesInput.value.trim();
    const duration = parseInt(durationInput.value) || 1; // Use 1 if no target set (backend requires > 0)

    // Validation
    if (!title || title.length < 3) {
        alert('Session title must be at least 3 characters');
        return;
    }

    try {
        // Create session in backend (backend will auto-set start_time)
        const { data: session } = await api.post('/study_sessions', {
            study_session: {
                title: title,
                duration: duration,
                notes: notes || null
            }
        });

        // Store session data including backend's start_time
        currentSession = session;

        // Start timer
        timerState = 'running';
        elapsedSeconds = 0;
        startTimerInterval();
        updateTimerDisplay();

        // Update UI
        updateButtonStates('running');
        setFormInputsDisabled(true);

        // Show target info if duration was set
        const targetInfo = document.getElementById('targetInfo');
        const targetText = document.getElementById('targetText');
        if (targetInfo && targetText) {
            targetText.textContent = `Target: ${duration} minutes`;
            targetInfo.style.display = 'flex';
        }

    } catch (error) {
        console.error('Start session error:', error);
        alert(error.message || 'Failed to start session');
    }
}

function handlePauseSession() {
    if (timerState === 'running') {
        // Pause the timer
        timerState = 'paused';
        stopTimerInterval();
        updateTimerDisplay();
        updateButtonStates('paused');
    } else if (timerState === 'paused') {
        // Resume the timer
        timerState = 'running';
        startTimerInterval();
        updateTimerDisplay();
        updateButtonStates('running');
    }
}

function handleCompleteSession() {
    // Stop timer
    stopTimerInterval();
    timerState = 'idle';

    // Show focus rating modal
    showFocusRatingModal();
}

// ========== SESSION COMPLETION FLOW ==========
function showFocusRatingModal() {
    const modal = document.getElementById('ratingModal');
    const finalDuration = document.getElementById('finalDuration');
    const finalTitle = document.getElementById('finalTitle');

    if (finalDuration) {
        finalDuration.textContent = formatTime(elapsedSeconds);
    }

    if (finalTitle && currentSession) {
        finalTitle.textContent = currentSession.title;
    }

    if (modal) {
        modal.style.display = 'flex';
    }
}

async function handleRatingSelection(rating) {
    if (!currentSession) return;

    // Disable all rating buttons to prevent double-click
    document.querySelectorAll('.rating-btn').forEach(btn => {
        btn.disabled = true;
        btn.style.opacity = '0.5';
    });

    try {
        // Calculate end_time based on backend's start_time + elapsed seconds
        const startTime = new Date(currentSession.start_time);
        const endTime = new Date(startTime.getTime() + elapsedSeconds * 1000);

        // Update session with end_time and rating
        const { data: response } = await api.patch(`/study_sessions/${currentSession.id}`, {
            study_session: {
                end_time: endTime.toISOString(),
                focus_rating: rating
            }
        });

        // Show rewards in the same modal (don't close it)
        if (response.rewards && response.streak) {
            showRewardsNotification(response.rewards, response.streak);
        }

        // Reset form and reload sessions (but don't close modal yet)
        resetSessionForm();
        await loadSessions();

    } catch (error) {
        console.error('Complete session error:', error);
        alert(error.message || 'Failed to save session');

        // Re-enable buttons on error
        document.querySelectorAll('.rating-btn').forEach(btn => {
            btn.disabled = false;
            btn.style.opacity = '1';
        });
    }
}

function showRewardsNotification(rewards, streak) {
    // Convert the rating modal to show rewards
    const modal = document.getElementById('ratingModal');
    const modalContent = modal.querySelector('.modal-content');

    if (!modalContent) return;

    // Build rewards HTML with detailed breakdown
    let rewardsHTML = `
        <h2 class="modal-title">🎉 Session Complete!</h2>
        <p class="modal-subtitle">Great work on completing your session!</p>

        <div style="background: rgba(16, 185, 129, 0.1); border: 2px solid rgba(16, 185, 129, 0.3); border-radius: 0.75rem; padding: 1.5rem; margin: 1.5rem 0;">
            <div style="text-align: center; margin-bottom: 1rem;">
                <div style="font-size: 3rem; font-weight: bold; color: #10b981;">
                    +${rewards.xp} XP
                </div>
            </div>

            <div style="display: flex; flex-direction: column; gap: 0.75rem; font-size: 0.875rem;">
                <div style="display: flex; justify-content: space-between; padding: 0.5rem; background: rgba(255, 255, 255, 0.05); border-radius: 0.5rem;">
                    <span style="color: var(--muted);">Base XP (${Math.round(rewards.base_xp / 1)} min):</span>
                    <span style="color: var(--foreground); font-weight: 600;">+${rewards.base_xp} XP</span>
                </div>
                ${rewards.bonus_xp > 0 ? `
                <div style="display: flex; justify-content: space-between; padding: 0.5rem; background: rgba(245, 158, 11, 0.1); border-radius: 0.5rem;">
                    <span style="color: #f59e0b;">Bonus (exceeded target):</span>
                    <span style="color: #f59e0b; font-weight: 600;">+${rewards.bonus_xp} XP</span>
                </div>
                ` : ''}
            </div>
        </div>

        <div style="display: flex; flex-direction: column; gap: 0.75rem; margin: 1rem 0;">
            ${rewards.goal_reached ? `
            <div style="display: flex; align-items: center; gap: 0.75rem; padding: 0.75rem; background: rgba(16, 185, 129, 0.1); border-radius: 0.5rem;">
                <span style="font-size: 1.5rem;">🎯</span>
                <span style="color: #10b981; font-weight: 600;">Target Reached!</span>
            </div>
            ` : ''}

            ${rewards.level_up ? `
            <div style="display: flex; align-items: center; gap: 0.75rem; padding: 0.75rem; background: rgba(245, 158, 11, 0.1); border-radius: 0.5rem;">
                <span style="font-size: 1.5rem;">🆙</span>
                <span style="color: #f59e0b; font-weight: 600;">Level Up! Now Level ${rewards.new_level}!</span>
            </div>
            ` : ''}

            <div style="display: flex; align-items: center; gap: 0.75rem; padding: 0.75rem; background: rgba(239, 68, 68, 0.1); border-radius: 0.5rem;">
                <span style="font-size: 1.5rem;">🔥</span>
                <span style="color: #ef4444; font-weight: 600;">Streak: ${streak.streak} ${streak.streak === 1 ? 'day' : 'days'}</span>
            </div>
        </div>

        <button class="btn-primary" onclick="document.getElementById('ratingModal').style.display='none'; location.reload();" style="width: 100%; margin-top: 1rem; padding: 1rem; font-size: 1rem; border: none; cursor: pointer;">
            Continue
        </button>
    `;

    modalContent.innerHTML = rewardsHTML;
}

function resetSessionForm() {
    // Clear form inputs
    document.getElementById('sessionTitle').value = '';
    document.getElementById('sessionNotes').value = '';
    document.getElementById('sessionDuration').value = '';

    // Reset timer display
    elapsedSeconds = 0;
    updateTimerDisplay();

    // Reset state
    timerState = 'idle';
    currentSession = null;

    // Update UI
    updateButtonStates('idle');
    setFormInputsDisabled(false);

    // Hide target info
    const targetInfo = document.getElementById('targetInfo');
    if (targetInfo) {
        targetInfo.style.display = 'none';
    }
}

// ========== STATS CALCULATIONS ==========
function updateStatsCards(sessions) {
    const statCardValues = document.querySelectorAll('.stat-card-value');

    if (statCardValues.length >= 4) {
        statCardValues[0].textContent = calculateTodayStudyTime(sessions);
        statCardValues[1].textContent = calculateWeekStudyTime(sessions);
        statCardValues[2].textContent = calculateCompletedCount(sessions);
        statCardValues[3].textContent = calculateAverageDuration(sessions);
    }
}

function calculateTodayStudyTime(sessions) {
    const today = new Date();
    today.setHours(0, 0, 0, 0);

    const todaySessions = sessions.filter(s => {
        if (!s.completed || !s.start_time) return false;
        const startDate = new Date(s.start_time);
        startDate.setHours(0, 0, 0, 0);
        return startDate.getTime() === today.getTime();
    });

    const totalMinutes = todaySessions.reduce((sum, s) => sum + (s.actual_duration || 0), 0);
    return formatDuration(totalMinutes);
}

function calculateWeekStudyTime(sessions) {
    const now = new Date();
    const weekStart = new Date(now);
    weekStart.setDate(now.getDate() - now.getDay()); // Start of week (Sunday)
    weekStart.setHours(0, 0, 0, 0);

    const weekSessions = sessions.filter(s => {
        if (!s.completed || !s.start_time) return false;
        return new Date(s.start_time) >= weekStart;
    });

    const totalMinutes = weekSessions.reduce((sum, s) => sum + (s.actual_duration || 0), 0);
    return formatDuration(totalMinutes);
}

function calculateCompletedCount(sessions) {
    return sessions.filter(s => s.completed).length;
}

function calculateAverageDuration(sessions) {
    const completed = sessions.filter(s => s.completed && s.actual_duration);
    if (completed.length === 0) return "0m";

    const totalMinutes = completed.reduce((sum, s) => sum + (s.actual_duration || 0), 0);
    const average = Math.round(totalMinutes / completed.length);

    return formatDuration(average);
}

// ========== RENDERING ==========
function renderSessionHistory(sessions) {
    const container = document.querySelector('.sessions-list');
    if (!container) return;

    container.innerHTML = '';

    // Only show completed sessions
    const completedSessions = sessions.filter(s => s.completed);

    if (completedSessions.length === 0) {
        container.innerHTML = '<p style="text-align: center; padding: 2rem; color: #666;">No sessions yet. Start your first study session!</p>';
        return;
    }

    // Sort by most recent first
    const sorted = [...completedSessions].sort((a, b) =>
        new Date(b.start_time) - new Date(a.start_time)
    );

    sorted.forEach(session => {
        const sessionItem = createSessionItem(session);
        container.appendChild(sessionItem);
    });
}

function createSessionItem(session) {
    const div = document.createElement('div');
    div.className = 'session-item';

    const formattedDate = formatSessionDate(session.start_time);
    const duration = formatDuration(session.actual_duration);
    const targetDuration = formatDuration(session.duration);
    const xpEarned = session.xp_earned || 0;

    div.innerHTML = `
        <div class="session-icon completed">✓</div>
        <div class="session-content">
            <h3 class="session-title">${escapeHtml(session.title)}</h3>
            <p class="session-meta">
                <span class="session-date">🗓️ ${formattedDate}</span>
                <span class="session-duration">⏱️ ${duration}</span>
                ${session.focus_rating ? `<span class="session-rating">⭐ Focus: ${session.focus_rating}/5</span>` : ''}
            </p>
            ${session.notes ? `<p class="session-description">${escapeHtml(session.notes)}</p>` : ''}
        </div>
        <div class="session-stats">
            ${session.duration && session.duration > 1 ? `
            <div class="stat-mini">
                <div class="stat-mini-label">Target</div>
                <div class="stat-mini-value">${targetDuration}</div>
            </div>
            ` : ''}
            <div class="stat-mini">
                <div class="stat-mini-label">XP</div>
                <div class="stat-mini-value" style="color: #f59e0b;">+${xpEarned}</div>
            </div>
        </div>
    `;

    return div;
}

// ========== UI STATE MANAGEMENT ==========
function updateButtonStates(state) {
    const startBtn = document.getElementById('startBtn');
    const pauseBtn = document.getElementById('pauseBtn');
    const stopBtn = document.getElementById('stopBtn');

    switch (state) {
        case 'idle':
            startBtn.disabled = false;
            pauseBtn.disabled = true;
            stopBtn.disabled = true;
            break;

        case 'running':
            startBtn.disabled = true;
            pauseBtn.disabled = false;
            stopBtn.disabled = false;
            pauseBtn.innerHTML = '<span class="timer-btn-icon">⏸️</span><span>Pause</span>';
            break;

        case 'paused':
            startBtn.disabled = true;
            pauseBtn.disabled = false;
            stopBtn.disabled = false;
            pauseBtn.innerHTML = '<span class="timer-btn-icon">▶️</span><span>Resume</span>';
            break;
    }
}

function setFormInputsDisabled(disabled) {
    document.getElementById('sessionTitle').disabled = disabled;
    document.getElementById('sessionNotes').disabled = disabled;
    document.getElementById('sessionDuration').disabled = disabled;
}

// TEST HELPER: Create fake session for XP testing
// Usage in console: testSession(60, 30) creates 60min session with 30min target
window.testSession = async function(actualMinutes = 60, targetMinutes = 30, title = 'Test Session') {
    try {
        // Create session
        const { data: session } = await api.post('/study_sessions', {
            study_session: {
                title: title,
                duration: targetMinutes,
                notes: 'Auto-generated test session'
            }
        });

        console.log('Created session:', session.id);

        // Calculate start and end times
        const now = new Date();
        const startTime = new Date(session.start_time);
        const endTime = new Date(startTime.getTime() + actualMinutes * 60 * 1000);

        // Complete session
        const { data: response } = await api.patch(`/study_sessions/${session.id}`, {
            study_session: {
                end_time: endTime.toISOString(),
                focus_rating: Math.floor(Math.random() * 5) + 1 // Random 1-5
            }
        });

        console.log('Session completed!');
        console.log('XP earned:', response.rewards.xp);
        console.log('Level:', response.rewards.new_level || 'No level up');
        console.log('Streak:', response.streak.streak);

        // Reload sessions
        await loadSessions();

        return response;
    } catch (error) {
        console.error('Test session error:', error);
    }
};

// Quick XP gain test
window.quickXPTest = async function(count = 5) {
    console.log(`Creating ${count} test sessions...`);
    for (let i = 0; i < count; i++) {
        await window.testSession(60, 30, `Test Session ${i + 1}`);
        console.log(`Session ${i + 1}/${count} completed`);
    }
    console.log('All test sessions completed! Check your XP and level.');
};
