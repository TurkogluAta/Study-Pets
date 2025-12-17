require "test_helper"

class TasksControllerTest < ActionDispatch::IntegrationTest
  setup do
    @user = users(:one)
    @other_user = users(:two)
    @task = tasks(:one)
    @token = generate_test_token(@user)
  end

  # ========== INDEX TESTS ==========

  test "should get index with valid token" do
    get "/tasks", headers: { Authorization: "Bearer #{@token}" }, as: :json

    assert_response :success
    json = JSON.parse(response.body)
    assert_kind_of Array, json
  end

  test "should only return current user's tasks" do
    get "/tasks", headers: { Authorization: "Bearer #{@token}" }, as: :json

    json = JSON.parse(response.body)
    json.each do |task|
      assert_equal @user.id, task["user_id"]
    end
  end

  test "should not get index without authentication" do
    get "/tasks", as: :json

    assert_response :unauthorized
  end

  # ========== SHOW TESTS ==========

  test "should show own task" do
    get "/tasks/#{@task.id}",
      headers: { Authorization: "Bearer #{@token}" },
      as: :json

    assert_response :success
    json = JSON.parse(response.body)
    assert_equal @task.id, json["id"]
  end

  test "should not show other user's task" do
    other_task = @other_user.tasks.create!(
      title: "Other Task",
      status: "pending"
    )

    get "/tasks/#{other_task.id}",
      headers: { Authorization: "Bearer #{@token}" },
      as: :json

    assert_response :not_found
  end

  # ========== CREATE TESTS ==========

  test "should create task with valid data" do
    assert_difference("Task.count") do
      post "/tasks",
        headers: { Authorization: "Bearer #{@token}" },
        params: { task: { title: "New Task" } },
        as: :json
    end

    assert_response :created
    json = JSON.parse(response.body)
    assert_equal "New Task", json["title"]
    assert_equal @user.id, json["user_id"]
  end

  test "should not create task with invalid data" do
    assert_no_difference("Task.count") do
      post "/tasks",
        headers: { Authorization: "Bearer #{@token}" },
        params: { task: { title: "ab" } },
        as: :json
    end

    assert_response :unprocessable_entity
  end

  # ========== UPDATE TESTS ==========

  test "should update own task" do
    patch "/tasks/#{@task.id}",
      headers: { Authorization: "Bearer #{@token}" },
      params: { task: { title: "Updated" } },
      as: :json

    assert_response :success
    json = JSON.parse(response.body)
    assert_equal "Updated", json["title"]
  end

  test "should not update other user's task" do
    other_task = @other_user.tasks.create!(title: "Other", status: "pending")

    patch "/tasks/#{other_task.id}",
      headers: { Authorization: "Bearer #{@token}" },
      params: { task: { title: "Hacked" } },
      as: :json

    assert_response :not_found
  end

  # ========== DELETE TESTS ==========

  test "should destroy own task" do
    task = @user.tasks.create!(title: "To Delete", status: "pending")

    assert_difference("Task.count", -1) do
      delete "/tasks/#{task.id}",
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
