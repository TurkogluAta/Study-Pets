let tasksData = [];

document.addEventListener('DOMContentLoaded', async () => {
    if (!requireAuth()) return;

    await loadTasks();
});

async function loadTasks() {
    try {
        const { data } = await api.get('/tasks');
        tasksData = data;

        updateStatsCards(tasksData);
        renderTasksTable(tasksData);

    } catch (error) {
        console.error('Tasks load error:', error);
        const tbody = document.querySelector('.tasks-table tbody');
        if (tbody) {
            let message = 'Failed to load tasks.';

            if (error.message.includes('Session expired')) {
                // Will redirect automatically
                return;
            } else if (error.message.includes('Server error')) {
                message = 'Server error. Please try refreshing the page.';
            } else if (error.message.includes('not found')) {
                message = 'No tasks found or you may not have permission.';
            } else {
                message = `Failed to load tasks: ${error.message}`;
            }

            tbody.innerHTML = `<tr><td colspan="5" style="text-align: center; padding: 2rem; color: #e74c3c;">${message}</td></tr>`;
        }
    }
}

function updateStatsCards(tasks) {
    const statCardValues = document.querySelectorAll('.stat-card-value');

    if (statCardValues.length >= 3) {
        // Pending tasks (pending + in_progress)
        const pending = tasks.filter(t => t.status === 'pending' || t.status === 'in_progress').length;
        statCardValues[0].textContent = pending;

        // Tasks due this week
        const now = new Date();
        const weekFromNow = new Date(now.getTime() + 7 * 24 * 60 * 60 * 1000);
        const dueThisWeek = tasks.filter(t => {
            if (!t.due_date) return false;
            const dueDate = new Date(t.due_date);
            return dueDate >= now && dueDate <= weekFromNow;
        }).length;
        statCardValues[1].textContent = dueThisWeek;

        // High priority tasks
        const highPriority = tasks.filter(t => t.priority === 'high' && t.status !== 'completed').length;
        statCardValues[2].textContent = highPriority;
    }
}

function renderTasksTable(tasks) {
    const tbody = document.querySelector('.tasks-table tbody');
    if (!tbody) return;

    tbody.innerHTML = '';

    if (tasks.length === 0) {
        tbody.innerHTML = '<tr><td colspan="5" style="text-align: center; padding: 2rem; color: #666;">No tasks yet. Create your first task!</td></tr>';
        return;
    }

    tasks.forEach(task => {
        const row = createTaskRow(task);
        tbody.appendChild(row);
    });
}

function createTaskRow(task) {
    const tr = document.createElement('tr');
    tr.className = 'task-row';
    if (task.status === 'completed') {
        tr.classList.add('completed');
    }

    // Format due date
    const dueDate = task.due_date ? new Date(task.due_date).toLocaleDateString('en-US', {
        month: '2-digit',
        day: '2-digit',
        year: 'numeric'
    }) : 'No due date';

    // Priority chip styling
    const priorityClass = task.priority || 'normal';
    const priorityText = priorityClass.charAt(0).toUpperCase() + priorityClass.slice(1);

    // Status badge styling
    const status = STATUS_MAP[task.status] || STATUS_MAP['pending'];

    tr.innerHTML = `
        <td class="task-title">${escapeHtml(task.title)}</td>
        <td><span class="chip ${priorityClass}">${priorityText}</span></td>
        <td class="task-date">${dueDate}</td>
        <td><span class="badge ${status.class}">${status.text}</span></td>
        <td>
            <div class="action-buttons">
                <button class="action-btn" title="Edit" onclick="editTask(${task.id})">✏️</button>
                <button class="action-btn success" title="Complete" onclick="completeTask(${task.id})" ${task.status === 'completed' ? 'disabled' : ''}>✓</button>
                <button class="action-btn danger" title="Delete" onclick="deleteTask(${task.id})">🗑</button>
            </div>
        </td>
    `;

    return tr;
}

function editTask(taskId) {
    window.location.href = `task-form.html?id=${taskId}`;
}

async function completeTask(taskId) {
    if (!confirm('Mark this task as completed?')) return;

    try {
        await api.patch(`/tasks/${taskId}`, {
            task: { status: 'completed' }
        });

        await loadTasks();

    } catch (error) {
        console.error('Complete task error:', error);
        alert('Failed to complete task');
    }
}

async function deleteTask(taskId) {
    if (!confirm('Are you sure you want to delete this task? This action cannot be undone.')) return;

    try {
        await api.delete(`/tasks/${taskId}`);

        await loadTasks();

    } catch (error) {
        console.error('Delete task error:', error);
        alert('Failed to delete task');
    }
}
