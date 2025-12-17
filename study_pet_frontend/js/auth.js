// Login handler
function initLogin() {
    const form = document.getElementById('loginForm');
    if (!form) return;

    form.addEventListener('submit', async (e) => {
        e.preventDefault();

        const email = document.getElementById('email').value;
        const password = document.getElementById('password').value;

        try {
            const { data } = await api.post('/login', { email, password });

            if (data && data.token) {
                localStorage.setItem('auth_token', data.token);
                window.location.href = 'dashboard.html';
            } else {
                alert(data?.error || 'Invalid email or password. Please try again.');
            }
        } catch (error) {
            alert(error.message || 'An error occurred. Please try again.');
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
            alert('Passwords do not match!');
            return;
        }

        try {
            const { data } = await api.post('/register', {
                user: {
                    name,
                    username,
                    email,
                    password,
                    password_confirmation,
                    pet_name,
                    pet_type
                }
            });

            if (data && data.token) {
                localStorage.setItem('auth_token', data.token);
                window.location.href = 'dashboard.html';
            } else {
                // Show specific error messages
                if (data?.errors) {
                    // Handle Rails validation errors
                    const errorMessages = Object.entries(data.errors).map(([field, messages]) => {
                        const fieldName = field.charAt(0).toUpperCase() + field.slice(1).replace('_', ' ');
                        const errorList = Array.isArray(messages) ? messages.join(', ') : messages;
                        return `${fieldName}: ${errorList}`;
                    });

                    alert(errorMessages.join('\n'));
                } else if (data?.error) {
                    alert(data.error);
                } else {
                    alert('Registration failed. Please check your information and try again.');
                }
            }
        } catch (error) {
            alert(error.message || 'An error occurred. Please try again.');
            console.error('Registration error:', error);
        }
    });
}

// Initialize on page load
document.addEventListener('DOMContentLoaded', () => {
    initLogin();
    initRegister();
});