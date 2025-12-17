let editingTaskId = null;

document.addEventListener('DOMContentLoaded', async () => {
    if (!requireAuth()) return;

    // Set minimum date to today for due date picker
    const dueDateInput = document.getElementById('taskDueDate');
    if (dueDateInput) {
        const now = new Date();
        now.setMinutes(now.getMinutes() - now.getTimezoneOffset()); // Fix timezone
        dueDateInput.min = now.toISOString().slice(0, 16);
    }

    // Check if editing existing task
    const urlParams = new URLSearchParams(window.location.search);
    editingTaskId = urlParams.get('id');

    if (editingTaskId) {
        await loadTaskForEditing(editingTaskId);
    }

    // Setup form submission
    const form = document.getElementById('taskForm');
    if (form) {
        form.addEventListener('submit', handleSubmit);
    }
});

async function loadTaskForEditing(taskId) {
    try {
        const { data: task } = await api.get(`/tasks/${taskId}`);

        // Update header
        const headerTitle = document.querySelector('.header-title');
        if (headerTitle) {
            headerTitle.textContent = 'Edit Task';
        }

        // Populate form
        document.getElementById('taskTitle').value = task.title || '';
        document.getElementById('taskDescription').value = task.description || '';
        document.getElementById('taskPriority').value = task.priority || 'medium';
        document.getElementById('taskStatus').value = task.status || 'pending';

        // Format due_date for datetime-local input (YYYY-MM-DDTHH:MM)
        if (task.due_date) {
            const date = new Date(task.due_date);
            const formatted = date.toISOString().slice(0, 16);
            document.getElementById('taskDueDate').value = formatted;
        }

    } catch (error) {
        console.error('Load task error:', error);
        setTimeout(() => window.location.href = 'tasks.html', 2000);
    }
}

async function handleSubmit(e) {
    e.preventDefault();

    const taskData = {
        task: {
            title: document.getElementById('taskTitle').value.trim(),
            description: document.getElementById('taskDescription').value.trim(),
            priority: document.getElementById('taskPriority').value,
            status: document.getElementById('taskStatus').value,
            due_date: document.getElementById('taskDueDate').value || null
        }
    };

    // HTML5 validation handles required fields

    // Show loading state
    const submitBtn = e.target.querySelector('button[type="submit"]');
    const originalText = submitBtn.textContent;
    submitBtn.disabled = true;
    submitBtn.textContent = editingTaskId ? 'Updating...' : 'Creating...';

    try {
        if (editingTaskId) {
            // Update existing task
            await api.patch(`/tasks/${editingTaskId}`, taskData);
        } else {
            // Create new task
            await api.post('/tasks', taskData);
        }

        // Wait a bit to ensure DB commit completes
        await new Promise(resolve => setTimeout(resolve, 200));

        // Redirect back to tasks list
        window.location.href = 'tasks.html';

    } catch (error) {
        // Re-enable form
        submitBtn.disabled = false;
        submitBtn.textContent = originalText;

        console.error('Save task error:', error);
        alert(`Failed to ${editingTaskId ? 'update' : 'create'} task: ${error.message}`);
    }
}
