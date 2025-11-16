require "test_helper"

class UsersControllerTest < ActionDispatch::IntegrationTest
  setup do
    @user = users(:one)
  end

  test "should get index" do
    get users_url, as: :json
    assert_response :success
  end

  test "should create user" do
    assert_difference("User.count") do
      post users_url, params: { user: { email: @user.email, experience_points: @user.experience_points, last_study_date: @user.last_study_date, level: @user.level, name: @user.name, password_digest: @user.password_digest, pet_energy: @user.pet_energy, pet_mood: @user.pet_mood, pet_name: @user.pet_name, pet_type: @user.pet_type, streak_days: @user.streak_days, total_study_time: @user.total_study_time, username: @user.username } }, as: :json
    end

    assert_response :created
  end

  test "should show user" do
    get user_url(@user), as: :json
    assert_response :success
  end

  test "should update user" do
    patch user_url(@user), params: { user: { email: @user.email, experience_points: @user.experience_points, last_study_date: @user.last_study_date, level: @user.level, name: @user.name, password_digest: @user.password_digest, pet_energy: @user.pet_energy, pet_mood: @user.pet_mood, pet_name: @user.pet_name, pet_type: @user.pet_type, streak_days: @user.streak_days, total_study_time: @user.total_study_time, username: @user.username } }, as: :json
    assert_response :success
  end

  test "should destroy user" do
    assert_difference("User.count", -1) do
      delete user_url(@user), as: :json
    end

    assert_response :no_content
  end
end
