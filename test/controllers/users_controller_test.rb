require "test_helper"

class UsersControllerTest < ActionDispatch::IntegrationTest
  setup do
    @user = users(:one)
    @token = generate_test_token(@user)
  end

  # ========== REGISTRATION TESTS ==========

  test "should register new user with valid data" do
    assert_difference("User.count") do
      post "/register", params: {
        user: {
          username: "newuser",
          email: "newuser@test.com",
          password: "password123",
          password_confirmation: "password123",
          name: "New User",
          pet_name: "Fluffy",
          pet_type: "cat"
        }
      }, as: :json
    end

    assert_response :created
    json = JSON.parse(response.body)
    assert json["user"]
    assert json["token"]
    assert_equal "newuser", json["user"]["username"]
  end

  test "should not register user with invalid data" do
    assert_no_difference("User.count") do
      post "/register", params: {
        user: {
          username: "ab",  # Too short
          email: "invalid",
          password: "123"
        }
      }, as: :json
    end

    assert_response :unprocessable_content
    json = JSON.parse(response.body)
    assert json["errors"]
  end

  # ========== LOGIN TESTS ==========

  test "should login with valid credentials" do
    post "/login", params: {
      email: "alice@test.com",
      password: "password"
    }, as: :json

    assert_response :success
    json = JSON.parse(response.body)
    assert json["user"]
    assert json["token"]
  end

  test "should not login with invalid credentials" do
    post "/login", params: {
      email: "alice@test.com",
      password: "wrongpassword"
    }, as: :json

    assert_response :unauthorized
  end

  # ========== PROFILE TESTS ==========

  test "should get profile with valid token" do
    get "/profile", headers: { Authorization: "Bearer #{@token}" }, as: :json

    assert_response :success
    json = JSON.parse(response.body)
    assert_equal @user.id, json["id"]
    assert_equal @user.username, json["username"]
  end

  test "should not get profile without token" do
    get "/profile", as: :json

    assert_response :unauthorized
  end

  test "should update profile" do
    patch "/profile",
      headers: { Authorization: "Bearer #{@token}" },
      params: { user: { name: "Updated Name" } },
      as: :json

    assert_response :success
    json = JSON.parse(response.body)
    assert_equal "Updated Name", json["name"]
  end

  test "should delete account" do
    assert_difference("User.count", -1) do
      delete "/profile", headers: { Authorization: "Bearer #{@token}" }, as: :json
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
