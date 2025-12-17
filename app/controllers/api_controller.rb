class ApiController < ApplicationController
  skip_before_action :authenticate_user, only: [:index]

  def index
    render html: api_documentation.html_safe
  end

  private

  def api_documentation
    <<-HTML
      <!DOCTYPE html>
      <html>
      <head>
        <meta charset="utf-8">
        <meta name="viewport" content="width=device-width, initial-scale=1">
        <title>Study Pet API</title>
        <style>
          * { margin: 0; padding: 0; box-sizing: border-box; }
          body {
            font-family: -apple-system, BlinkMacSystemFont, 'Segoe UI', Arial, sans-serif;
            line-height: 1.6;
            color: #333;
            background: linear-gradient(135deg, #667eea 0%, #764ba2 100%);
            min-height: 100vh;
            padding: 20px;
          }
          .container {
            max-width: 900px;
            margin: 0 auto;
            background: white;
            border-radius: 12px;
            padding: 40px;
            box-shadow: 0 20px 60px rgba(0,0,0,0.3);
          }
          h1 {
            color: #667eea;
            margin-bottom: 10px;
            font-size: 2.5em;
          }
          .subtitle {
            color: #666;
            margin-bottom: 30px;
            font-size: 1.1em;
          }
          .section {
            margin-bottom: 30px;
          }
          h2 {
            color: #764ba2;
            margin-bottom: 15px;
            padding-bottom: 10px;
            border-bottom: 2px solid #f0f0f0;
          }
          .endpoint {
            background: #f8f9fa;
            border-left: 4px solid #667eea;
            padding: 15px;
            margin-bottom: 15px;
            border-radius: 4px;
          }
          .method {
            display: inline-block;
            padding: 4px 12px;
            border-radius: 4px;
            font-weight: bold;
            font-size: 0.85em;
            margin-right: 10px;
          }
          .post { background: #28a745; color: white; }
          .get { background: #17a2b8; color: white; }
          .patch, .put { background: #ffc107; color: #333; }
          .delete { background: #dc3545; color: white; }
          .path {
            font-family: 'Courier New', monospace;
            color: #333;
            font-weight: 600;
          }
          .desc {
            color: #666;
            margin-top: 8px;
            font-size: 0.95em;
          }
          .auth-required {
            display: inline-block;
            background: #fff3cd;
            color: #856404;
            padding: 2px 8px;
            border-radius: 3px;
            font-size: 0.8em;
            margin-left: 10px;
          }
          .base-url {
            background: #e9ecef;
            padding: 12px;
            border-radius: 6px;
            font-family: 'Courier New', monospace;
            margin-bottom: 30px;
            font-size: 1.1em;
          }
          .status {
            display: inline-block;
            background: #28a745;
            color: white;
            padding: 6px 12px;
            border-radius: 20px;
            font-size: 0.9em;
            margin-bottom: 20px;
          }
        </style>
      </head>
      <body>
        <div class="container">
          <h1>🐾 Study Pet API</h1>
          <p class="subtitle">Backend API for Study Pet - Gamified Study Management System</p>
          <span class="status">✓ API Active</span>

          <div class="base-url">
            <strong>Base URL:</strong> #{request.base_url}
          </div>

          <div class="section">
            <h2>🔐 Authentication</h2>
            <div class="endpoint">
              <span class="method post">POST</span>
              <span class="path">/register</span>
              <div class="desc">Create a new user account</div>
            </div>
            <div class="endpoint">
              <span class="method post">POST</span>
              <span class="path">/login</span>
              <div class="desc">Login and receive authentication token</div>
            </div>
          </div>

          <div class="section">
            <h2>👤 User Profile</h2>
            <div class="endpoint">
              <span class="method get">GET</span>
              <span class="path">/profile</span>
              <span class="auth-required">🔒 Auth Required</span>
              <div class="desc">Get current user profile information</div>
            </div>
            <div class="endpoint">
              <span class="method patch">PATCH</span>
              <span class="path">/profile</span>
              <span class="auth-required">🔒 Auth Required</span>
              <div class="desc">Update user profile</div>
            </div>
            <div class="endpoint">
              <span class="method delete">DELETE</span>
              <span class="path">/profile</span>
              <span class="auth-required">🔒 Auth Required</span>
              <div class="desc">Delete user account</div>
            </div>
          </div>

          <div class="section">
            <h2>📝 Tasks</h2>
            <div class="endpoint">
              <span class="method get">GET</span>
              <span class="path">/tasks</span>
              <span class="auth-required">🔒 Auth Required</span>
              <div class="desc">List all user tasks</div>
            </div>
            <div class="endpoint">
              <span class="method post">POST</span>
              <span class="path">/tasks</span>
              <span class="auth-required">🔒 Auth Required</span>
              <div class="desc">Create a new task</div>
            </div>
            <div class="endpoint">
              <span class="method get">GET</span>
              <span class="path">/tasks/:id</span>
              <span class="auth-required">🔒 Auth Required</span>
              <div class="desc">Get specific task details</div>
            </div>
            <div class="endpoint">
              <span class="method patch">PATCH</span>
              <span class="path">/tasks/:id</span>
              <span class="auth-required">🔒 Auth Required</span>
              <div class="desc">Update a task</div>
            </div>
            <div class="endpoint">
              <span class="method delete">DELETE</span>
              <span class="path">/tasks/:id</span>
              <span class="auth-required">🔒 Auth Required</span>
              <div class="desc">Delete a task</div>
            </div>
          </div>

          <div class="section">
            <h2>📚 Study Sessions</h2>
            <div class="endpoint">
              <span class="method get">GET</span>
              <span class="path">/study_sessions</span>
              <span class="auth-required">🔒 Auth Required</span>
              <div class="desc">List all study sessions</div>
            </div>
            <div class="endpoint">
              <span class="method post">POST</span>
              <span class="path">/study_sessions</span>
              <span class="auth-required">🔒 Auth Required</span>
              <div class="desc">Create a new study session</div>
            </div>
            <div class="endpoint">
              <span class="method get">GET</span>
              <span class="path">/study_sessions/:id</span>
              <span class="auth-required">🔒 Auth Required</span>
              <div class="desc">Get specific session details</div>
            </div>
            <div class="endpoint">
              <span class="method patch">PATCH</span>
              <span class="path">/study_sessions/:id</span>
              <span class="auth-required">🔒 Auth Required</span>
              <div class="desc">Update a study session</div>
            </div>
            <div class="endpoint">
              <span class="method delete">DELETE</span>
              <span class="path">/study_sessions/:id</span>
              <span class="auth-required">🔒 Auth Required</span>
              <div class="desc">Delete a study session</div>
            </div>
          </div>

          <div class="section">
            <h2>🏥 Health Check</h2>
            <div class="endpoint">
              <span class="method get">GET</span>
              <span class="path">/up</span>
              <div class="desc">Server health check endpoint</div>
            </div>
          </div>

          <div style="margin-top: 40px; padding-top: 20px; border-top: 2px solid #f0f0f0; color: #999; text-align: center;">
            <p>Authentication: Include <code>Authorization: Bearer &lt;token&gt;</code> header for protected endpoints</p>
          </div>
        </div>
      </body>
      </html>
    HTML
  end
end
