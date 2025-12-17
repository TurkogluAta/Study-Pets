require "test_helper"

class StudySessionsControllerTest < ActionDispatch::IntegrationTest
  setup do
    @user = users(:one)
    @other_user = users(:two)
    @session = study_sessions(:one)
    @token = generate_test_token(@user)
  end

  # ========== INDEX TESTS ==========

  test "should get index with valid token" do
    get "/study_sessions", headers: { Authorization: "Bearer #{@token}" }, as: :json

    assert_response :success
    json = JSON.parse(response.body)
    assert_kind_of Array, json
  end

  test "should only return current user's sessions" do
    get "/study_sessions", headers: { Authorization: "Bearer #{@token}" }, as: :json

    json = JSON.parse(response.body)
    json.each do |session|
      assert_equal @user.id, session["user_id"]
    end
  end

  test "should not get index without authentication" do
    get "/study_sessions", as: :json

    assert_response :unauthorized
  end

  # ========== SHOW TESTS ==========

  test "should show own study_session" do
    get "/study_sessions/#{@session.id}",
      headers: { Authorization: "Bearer #{@token}" },
      as: :json

    assert_response :success
    json = JSON.parse(response.body)
    assert_equal @session.id, json["id"]
  end

  test "should not show other user's study_session" do
    other_session = @other_user.study_sessions.create!(
      title: "Other Session",
      duration: 30
    )

    get "/study_sessions/#{other_session.id}",
      headers: { Authorization: "Bearer #{@token}" },
      as: :json

    assert_response :not_found
  end

  # ========== CREATE TESTS ==========

  test "should create study_session with valid data" do
    assert_difference("StudySession.count") do
      post "/study_sessions",
        headers: { Authorization: "Bearer #{@token}" },
        params: { study_session: { title: "New Session", duration: 45 } },
        as: :json
    end

    assert_response :created
    json = JSON.parse(response.body)
    assert_equal "New Session", json["title"]
    assert_equal @user.id, json["user_id"]
  end

  test "should not create study_session with invalid data" do
    assert_no_difference("StudySession.count") do
      post "/study_sessions",
        headers: { Authorization: "Bearer #{@token}" },
        params: { study_session: { title: "ab", duration: -5 } },
        as: :json
    end

    assert_response :unprocessable_entity
  end

  # ========== UPDATE TESTS ==========

  test "should update own study_session" do
    incomplete = @user.study_sessions.create!(
      title: "Test",
      duration: 30,
      completed: false
    )

    patch "/study_sessions/#{incomplete.id}",
      headers: { Authorization: "Bearer #{@token}" },
      params: { study_session: { notes: "Updated" } },
      as: :json

    assert_response :success
    json = JSON.parse(response.body)
    assert_equal "Updated", json["notes"]
  end

  test "should not update other user's study_session" do
    other_session = @other_user.study_sessions.create!(
      title: "Other",
      duration: 30
    )

    patch "/study_sessions/#{other_session.id}",
      headers: { Authorization: "Bearer #{@token}" },
      params: { study_session: { title: "Hacked" } },
      as: :json

    assert_response :not_found
  end

  # ========== GAMIFICATION INTEGRATION TESTS ==========

  test "should trigger gamification when completing session" do
    session = @user.study_sessions.create!(
      title: "Test Session",
      duration: 60,
      start_time: 2.hours.ago
    )

    initial_xp = @user.experience_points

    patch "/study_sessions/#{session.id}",
      headers: { Authorization: "Bearer #{@token}" },
      params: { study_session: { end_time: 1.hour.ago } },
      as: :json

    assert_response :success

    @user.reload
    assert_operator @user.experience_points, :>, initial_xp
  end

  test "should award bonus XP when exceeding goal" do
    session = @user.study_sessions.create!(
      title: "Goal Test",
      duration: 30,
      start_time: 2.hours.ago
    )

    initial_xp = @user.experience_points

    patch "/study_sessions/#{session.id}",
      headers: { Authorization: "Bearer #{@token}" },
      params: { study_session: { end_time: 1.hour.ago } },
      as: :json

    @user.reload
    # Base: 60 XP, Bonus: 60 XP = 120 total
    assert_equal initial_xp + 120, @user.experience_points
  end

  # ========== DELETE TESTS ==========

  test "should destroy own study_session" do
    session = @user.study_sessions.create!(title: "To Delete", duration: 30)

    assert_difference("StudySession.count", -1) do
      delete "/study_sessions/#{session.id}",
        headers: { Authorization: "Bearer #{@token}" },
        as: :json
    end

    assert_response :no_content
  end

  private

  def generate_test_token(user)
    JWT.encode(
      {
        user_id: user.id,
        exp: 24.hours.from_now.to_i
      },
      Rails.application.secret_key_base
    )
  end
end
