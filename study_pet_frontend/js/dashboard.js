// Require authentication on page load
document.addEventListener('DOMContentLoaded', async () => {
    if (!requireAuth()) return;

    await loadDashboard();
});

async function loadDashboard() {
    try {
        // Fetch user profile
        const { data: user } = await api.get('/profile');

        // Fetch task counts
        const { data: tasks } = await api.get('/tasks');

        // Fetch session counts
        const { data: sessions } = await api.get('/study_sessions');

        // Update UI
        updateUserInfo(user);
        updatePetCard(user);
        updateStats(user, tasks, sessions);

    } catch (error) {
        console.error('Dashboard load error:', error);
    }
}

function updateUserInfo(user) {
    const headerTitle = document.querySelector('.header-title');
    if (headerTitle) {
        headerTitle.textContent = `Welcome back, ${user.name}`;
    }
}

function updatePetCard(user) {
    // Pet name and type
    const petName = document.querySelector('.pet-name');
    if (petName) {
        petName.textContent = user.pet_name;
    }

    const petLevel = document.querySelector('.pet-level');
    if (petLevel) {
        const petType = user.pet_type.charAt(0).toUpperCase() + user.pet_type.slice(1);
        petLevel.textContent = `Level ${user.level} • ${petType}`;
    }

    // Mood display - first stat-value in pet-stats
    const petStats = document.querySelector('.pet-stats');
    if (petStats) {
        const moodValue = petStats.querySelector('.stat-value');
        if (moodValue) {
            const mood = user.pet_mood.charAt(0).toUpperCase() + user.pet_mood.slice(1);
            moodValue.textContent = mood;
        }
    }

    // Energy percentage
    const energyBar = document.querySelector('.progress-fill.energy');
    if (energyBar) {
        const energyValue = energyBar.parentElement.previousElementSibling.querySelector('.stat-value');
        if (energyValue) {
            energyValue.textContent = `${user.pet_energy}%`;
        }
        energyBar.style.width = `${user.pet_energy}%`;
    }

    // XP calculation (100 XP per level)
    const xpProgress = user.experience_points % 100;
    const xpBar = document.querySelector('.progress-fill.xp');
    if (xpBar) {
        const xpValue = xpBar.parentElement.previousElementSibling.querySelector('.stat-value');
        if (xpValue) {
            xpValue.textContent = `${xpProgress} / 100`;
        }
        xpBar.style.width = `${xpProgress}%`;
    }
}

function updateStats(user, tasks, sessions) {
    const statCardValues = document.querySelectorAll('.stat-card-value');

    if (statCardValues.length >= 4) {
        // Streak days
        statCardValues[0].textContent = user.streak_days;

        // Total study time (convert minutes to hours and minutes)
        statCardValues[1].textContent = formatDuration(user.total_study_time);

        // Completed tasks count
        const completedTasks = tasks.filter(t => t.status === 'completed').length;
        statCardValues[2].textContent = completedTasks;

        // Completed sessions count
        const completedSessions = sessions.filter(s => s.completed).length;
        statCardValues[3].textContent = completedSessions;
    }
}
