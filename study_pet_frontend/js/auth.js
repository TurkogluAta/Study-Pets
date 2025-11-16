const API_BASE_URL = 'http://localhost:3000';

// Toast notification function
function showToast(message, type = 'error') {
    const container = document.getElementById('toastContainer');
    container.style.display = 'block';

    const toast = document.createElement('div');
    toast.className = `toast ${type}`;
    toast.innerHTML = `
        <span class="material-symbols-outlined toast-icon">
            ${type === 'success' ? 'check_circle' : 'error'}
        </span>
        <div class="toast-content">
            <h3>${type === 'success' ? 'Success' : (type === 'error' ? 'Error' : 'Info')}</h3>
            <p>${message}</p>
        </div>
    `;

    container.appendChild(toast);

    setTimeout(() => {
        toast.remove();
        if (container.children.length === 0) {
            container.style.display = 'none';
        }
    }, 5000);
}

// Login handler
function initLogin() {
    const form = document.getElementById('loginForm');
    if (!form) return;

    form.addEventListener('submit', async (e) => {
        e.preventDefault();

        const email = document.getElementById('email').value;
        const password = document.getElementById('password').value;

        try {
            const response = await fetch(`${API_BASE_URL}/login`, {
                method: 'POST',
                headers: {
                    'Content-Type': 'application/json',
                },
                body: JSON.stringify({ email, password })
            });

            const data = await response.json();

            if (response.ok && data.token) {
                localStorage.setItem('auth_token', data.token);
                window.location.href = 'dashboard.html';
            } else {
                showToast(data.error || 'Invalid email or password. Please try again.');
            }
        } catch (error) {
            showToast('An error occurred. Please try again.');
            console.error('Login error:', error);
        }
    });
}

// Register handler
function initRegister() {
    const form = document.getElementById('registerForm');
    if (!form) return;

    form.addEventListener('submit', async (e) => {
        e.preventDefault();

        const name = document.getElementById('name').value;
        const username = document.getElementById('username').value;
        const email = document.getElementById('email').value;
        const password = document.getElementById('password').value;
        const password_confirmation = document.getElementById('password_confirmation').value;
        const pet_name = document.getElementById('pet_name').value;
        const pet_type = document.getElementById('pet_type').value;

        // Validate passwords match
        if (password !== password_confirmation) {
            showToast('Passwords do not match!');
            return;
        }

        try {
            const requestData = {
                user: {
                    name: name,
                    username: username,
                    email: email,
                    password: password,
                    password_confirmation: password_confirmation,
                    pet_name: pet_name,
                    pet_type: pet_type
                }
            };

            const response = await fetch(`${API_BASE_URL}/register`, {
                method: 'POST',
                headers: {
                    'Content-Type': 'application/json',
                },
                body: JSON.stringify(requestData)
            });

            const data = await response.json();

            if (data.token) {
                localStorage.setItem('auth_token', data.token);
                window.location.href = 'dashboard.html';
            } else {
                // Show specific error messages
                if (data.errors) {
                    // Handle Rails validation errors (e.g., { email: ["has already been taken"], username: ["is too short"] })
                    const errorMessages = Object.entries(data.errors).map(([field, messages]) => {
                        const fieldName = field.charAt(0).toUpperCase() + field.slice(1).replace('_', ' ');
                        const errorList = Array.isArray(messages) ? messages.join(', ') : messages;
                        return `${fieldName}: ${errorList}`;
                    });

                    // Show each error separately
                    errorMessages.forEach(msg => showToast(msg));
                } else if (data.error) {
                    showToast(data.error);
                } else {
                    showToast('Registration failed. Please check your information and try again.');
                }
            }
        } catch (error) {
            showToast('An error occurred. Please try again.');
            console.error('Registration error:', error);
        }
    });
}

// Initialize on page load
document.addEventListener('DOMContentLoaded', () => {
    initLogin();
    initRegister();
});