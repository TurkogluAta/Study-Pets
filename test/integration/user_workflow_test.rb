require "test_helper"

class UserWorkflowTest < ActionDispatch::IntegrationTest
  test "complete user registration and login workflow" do
    # Register new user
    post "/register", params: {
      user: {
        username: "newuser",
        email: "newuser@test.com",
        password: "password123",
        password_confirmation: "password123",
        name: "New User",
        pet_name: "Buddy",
        pet_type: "dog"
      }
    }, as: :json

    assert_response :created
    json = JSON.parse(response.body)
    assert json["user"]
    assert json["token"]
    token = json["token"]

    # Login with credentials
    post "/login", params: {
      email: "newuser@test.com",
      password: "password123"
    }, as: :json

    assert_response :success
    json = JSON.parse(response.body)
    assert json["token"]

    # Access and update profile
    get "/profile", headers: { Authorization: "Bearer #{token}" }, as: :json
    assert_response :success

    patch "/profile",
      headers: { Authorization: "Bearer #{token}" },
      params: { user: { name: "Updated Name" } },
      as: :json

    assert_response :success
    json = JSON.parse(response.body)
    assert_equal "Updated Name", json["name"]
  end

  test "complete study session workflow with gamification" do
    user = User.create!(
      username: "testuser",
      email: "test@test.com",
      password: "password123",
      name: "Test User",
      pet_name: "Test Pet",
      pet_type: "cat"
    )

    token = JWT.encode(
      { user_id: user.id, exp: 24.hours.from_now.to_i },
      Rails.application.secret_key_base
    )

    initial_xp = user.experience_points

    # Create a study session
    post "/study_sessions",
      headers: { Authorization: "Bearer #{token}" },
      params: { study_session: { title: "Math Study", duration: 60 } },
      as: :json

    assert_response :created
    session_id = JSON.parse(response.body)["id"]

    # Complete the session
    patch "/study_sessions/#{session_id}",
      headers: { Authorization: "Bearer #{token}" },
      params: {
        study_session: {
          start_time: 75.minutes.ago,
          end_time: Time.current
        }
      },
      as: :json

    assert_response :success

    # Verify gamification worked
    user.reload
    assert_operator user.experience_points, :>, initial_xp
    assert_equal 75, user.total_study_time
  end
end
