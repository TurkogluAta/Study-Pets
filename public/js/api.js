const API_BASE_URL = window.location.origin;

// Get auth token from localStorage
function getAuthToken() {
    return localStorage.getItem('auth_token');
}

// Check if user is authenticated
function isAuthenticated() {
    return !!getAuthToken();
}

// Decode JWT and check if token is valid and not expired
function isTokenValid() {
    const token = getAuthToken();
    if (!token) return false;

    try {
        // JWT structure: header.payload.signature
        const payload = JSON.parse(atob(token.split('.')[1]));

        // Check if expired (exp is in seconds, Date.now() is in ms)
        if (payload.exp && payload.exp * 1000 < Date.now()) {
            localStorage.removeItem('auth_token');
            return false;
        }

        return true;
    } catch (e) {
        // Invalid token format
        localStorage.removeItem('auth_token');
        return false;
    }
}

// Redirect to login if not authenticated
function requireAuth() {
    if (!isTokenValid()) {
        window.location.href = 'index.html';
        return false;
    }
    return true;
}

// Core API fetch wrapper
async function apiRequest(endpoint, options = {}) {
    const token = getAuthToken();

    const config = {
        headers: {
            'Content-Type': 'application/json',
            ...(token && { 'Authorization': `Bearer ${token}` })
        },
        ...options
    };

    try {
        const response = await fetch(`${API_BASE_URL}${endpoint}`, config);

        // Try to parse JSON response
        let data = null;
        try {
            data = await response.json();
        } catch (e) {
            // Response might not be JSON (e.g., 204 No Content)
            data = null;
        }

        // Handle unauthorized
        if (response.status === 401) {
            localStorage.removeItem('auth_token');
            window.location.href = 'index.html';
            throw new Error('Session expired');
        }

        // Handle not found
        if (response.status === 404) {
            throw new Error('Resource not found');
        }

        // Handle forbidden
        if (response.status === 403) {
            throw new Error('You do not have permission to access this resource');
        }

        // Handle server errors
        if (response.status >= 500) {
            throw new Error('Server error. Please try again later.');
        }

        // Handle other errors
        if (!response.ok) {
            console.error('API Error Response:', data);

            // If we have a simple error message
            if (data?.error) {
                throw new Error(data.error);
            }

            // Fallback
            throw new Error(`Request failed with status ${response.status}`);
        }

        return { data, status: response.status, ok: response.ok };
    } catch (error) {
        console.error('API Error:', error);
        throw error;
    }
}

// Convenience methods
const api = {
    get: (endpoint) => apiRequest(endpoint, { method: 'GET' }),
    post: (endpoint, body) => apiRequest(endpoint, {
        method: 'POST',
        body: JSON.stringify(body)
    }),
    put: (endpoint, body) => apiRequest(endpoint, {
        method: 'PUT',
        body: JSON.stringify(body)
    }),
    patch: (endpoint, body) => apiRequest(endpoint, {
        method: 'PATCH',
        body: JSON.stringify(body)
    }),
    delete: (endpoint) => apiRequest(endpoint, { method: 'DELETE' })
};
