require "test_helper"

class UserTest < ActiveSupport::TestCase
  # Setup
  def setup
    @user = users(:one)
  end

  # ========== VALIDATION TESTS ==========

  test "should be valid with valid attributes" do
    assert @user.valid?
  end

  # Username validations
  test "should require username" do
    @user.username = nil
    assert_not @user.valid?
    assert_includes @user.errors[:username], "can't be blank"
  end

  test "should require username minimum 3 characters" do
    @user.username = "ab"
    assert_not @user.valid?
  end

  test "should require username maximum 50 characters" do
    @user.username = "a" * 51
    assert_not @user.valid?
  end

  test "should require unique username" do
    duplicate_user = @user.dup
    duplicate_user.email = "different@test.com"
    @user.save!
    assert_not duplicate_user.valid?
  end

  test "should enforce case-insensitive username uniqueness" do
    @user.save!
    duplicate_user = @user.dup
    duplicate_user.username = @user.username.upcase
    duplicate_user.email = "different@test.com"
    assert_not duplicate_user.valid?
  end

  # Email validations
  test "should require email" do
    @user.email = nil
    assert_not @user.valid?
    assert_includes @user.errors[:email], "can't be blank"
  end

  test "should accept valid email formats" do
    valid_emails = %w[user@example.com USER@foo.COM A_US-ER@foo.bar.org first.last@foo.jp alice+bob@baz.cn]
    valid_emails.each do |valid_email|
      @user.email = valid_email
      assert @user.valid?, "#{valid_email.inspect} should be valid"
    end
  end

  test "should reject invalid email formats" do
    invalid_emails = %w[userexample.com @example.com user@]
    invalid_emails.each do |invalid_email|
      @user.email = invalid_email
      assert_not @user.valid?, "#{invalid_email.inspect} should be invalid"
    end
  end

  test "should require unique email" do
    duplicate_user = @user.dup
    duplicate_user.username = "different"
    @user.save!
    assert_not duplicate_user.valid?
  end

  test "should enforce case-insensitive email uniqueness" do
    @user.save!
    duplicate_user = @user.dup
    duplicate_user.email = @user.email.upcase
    duplicate_user.username = "different"
    assert_not duplicate_user.valid?
  end

  # Name validations
  test "should require name" do
    @user.name = nil
    assert_not @user.valid?
  end

  test "should require name minimum 3 characters" do
    @user.name = "ab"
    assert_not @user.valid?
  end

  test "should require name maximum 50 characters" do
    @user.name = "a" * 51
    assert_not @user.valid?
  end

  # Pet validations
  test "should require pet_name" do
    @user.pet_name = nil
    assert_not @user.valid?
  end

  test "should require pet_name minimum 3 characters" do
    @user.pet_name = "ab"
    assert_not @user.valid?
  end

  test "should require pet_name maximum 30 characters" do
    @user.pet_name = "a" * 31
    assert_not @user.valid?
  end

  test "should require pet_type" do
    @user.pet_type = nil
    assert_not @user.valid?
  end

  test "should only allow cat or dog for pet_type" do
    valid_types = %w[cat dog]
    valid_types.each do |type|
      @user.pet_type = type
      assert @user.valid?, "#{type} should be valid"
    end
  end

  test "should reject invalid pet_types" do
    invalid_types = %w[bird fish hamster]
    invalid_types.each do |type|
      @user.pet_type = type
      assert_not @user.valid?, "#{type} should be invalid"
    end
  end

  # Password validations
  test "should require password for new users" do
    user = User.new(
      username: "testuser",
      email: "test@example.com",
      name: "Test User",
      pet_name: "Fluffy",
      pet_type: "cat"
    )
    assert_not user.valid?
    assert_includes user.errors[:password], "can't be blank"
  end

  test "should require password minimum 6 characters" do
    user = User.new(
      username: "testuser",
      email: "test@example.com",
      name: "Test User",
      pet_name: "Fluffy",
      pet_type: "cat",
      password: "short"
    )
    assert_not user.valid?
    assert_includes user.errors[:password], "is too short (minimum is 6 characters)"
  end

  test "should accept valid passwords" do
    user = User.new(
      username: "testuser",
      email: "test@example.com",
      name: "Test User",
      pet_name: "Fluffy",
      pet_type: "cat",
      password: "password123"
    )
    assert user.valid?
  end

  test "should authenticate with correct password" do
    user = User.create!(
      username: "testuser",
      email: "test@example.com",
      name: "Test User",
      pet_name: "Fluffy",
      pet_type: "cat",
      password: "password123"
    )
    assert user.authenticate("password123")
  end

  test "should not authenticate with incorrect password" do
    user = User.create!(
      username: "testuser",
      email: "test@example.com",
      name: "Test User",
      pet_name: "Fluffy",
      pet_type: "cat",
      password: "password123"
    )
    assert_not user.authenticate("wrongpassword")
  end

  # ========== CALLBACK TESTS ==========

  test "should strip whitespace from username on save" do
    user = User.create!(
      username: "  spaced  ",
      email: "upper@test.com",
      name: "Upper User",
      pet_name: "Fluffy",
      pet_type: "cat",
      password: "password123"
    )
    assert_equal "spaced", user.username
  end

  test "should normalize email to lowercase" do
    @user.email = "UPPER@EXAMPLE.COM"
    @user.save!
    assert_equal "upper@example.com", @user.email
  end

  test "should strip whitespace from username" do
    @user.username = "  spaced  "
    @user.save!
    assert_equal "spaced", @user.username
  end

  test "should strip whitespace from email" do
    @user.email = "  spaced@example.com  "
    @user.save!
    assert_equal "spaced@example.com", @user.email
  end

  test "should set default values on initialization" do
    user = User.new
    assert_equal 1, user.level
    assert_equal 0, user.experience_points
    assert_equal "happy", user.pet_mood
    assert_equal 100, user.pet_energy
    assert_equal 0, user.streak_days
    assert_equal 0, user.total_study_time
    assert_not_nil user.last_checked_at
  end

  # ========== ASSOCIATION TESTS ==========

  test "should have many tasks" do
    assert_respond_to @user, :tasks
  end

  test "should have many study_sessions" do
    assert_respond_to @user, :study_sessions
  end

  test "should destroy associated tasks when user is destroyed" do
    user = User.create!(
      username: "taskuser",
      email: "task@test.com",
      name: "Task User",
      pet_name: "Fluffy",
      pet_type: "cat",
      password: "password123"
    )
    user.tasks.create!(title: "Test Task", status: "pending")
    assert_difference 'Task.count', -1 do
      user.destroy
    end
  end

  test "should destroy associated study_sessions when user is destroyed" do
    user = User.create!(
      username: "sessionuser",
      email: "session@test.com",
      name: "Session User",
      pet_name: "Fluffy",
      pet_type: "cat",
      password: "password123"
    )
    user.study_sessions.create!(
      title: "Test Session",
      start_time: Time.current,
      duration: 30
    )
    assert_difference 'StudySession.count', -1 do
      user.destroy
    end
  end

  # ========== JSON SERIALIZATION TESTS ==========

  test "should exclude password_digest from JSON" do
    json = @user.as_json
    assert_not json.key?("password_digest")
  end

  test "should include other attributes in JSON" do
    json = @user.as_json
    assert json.key?("username")
    assert json.key?("email")
    assert json.key?("level")
    assert json.key?("pet_energy")
  end
end
