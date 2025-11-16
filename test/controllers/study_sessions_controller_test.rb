require "test_helper"

class StudySessionsControllerTest < ActionDispatch::IntegrationTest
  setup do
    @study_session = study_sessions(:one)
  end

  test "should get index" do
    get study_sessions_url, as: :json
    assert_response :success
  end

  test "should create study_session" do
    assert_difference("StudySession.count") do
      post study_sessions_url, params: { study_session: { completed: @study_session.completed, duration: @study_session.duration, focus_rating: @study_session.focus_rating, notes: @study_session.notes, start_time: @study_session.start_time, title: @study_session.title, user_id: @study_session.user_id } }, as: :json
    end

    assert_response :created
  end

  test "should show study_session" do
    get study_session_url(@study_session), as: :json
    assert_response :success
  end

  test "should update study_session" do
    patch study_session_url(@study_session), params: { study_session: { completed: @study_session.completed, duration: @study_session.duration, focus_rating: @study_session.focus_rating, notes: @study_session.notes, start_time: @study_session.start_time, title: @study_session.title, user_id: @study_session.user_id } }, as: :json
    assert_response :success
  end

  test "should destroy study_session" do
    assert_difference("StudySession.count", -1) do
      delete study_session_url(@study_session), as: :json
    end

    assert_response :no_content
  end
end
