require "test_helper"

class TaskTest < ActiveSupport::TestCase
  # Setup
  def setup
    @task = tasks(:one)
  end

  # ========== VALIDATION TESTS ==========

  test "should be valid with valid attributes" do
    assert @task.valid?
  end

  # Title validations
  test "should require title" do
    @task.title = nil
    assert_not @task.valid?
    assert_includes @task.errors[:title], "can't be blank"
  end

  test "should require title minimum 3 characters" do
    @task.title = "ab"
    assert_not @task.valid?
  end

  test "should require title maximum 100 characters" do
    @task.title = "a" * 101
    assert_not @task.valid?
  end

  # Status validations
  test "should accept valid status values" do
    valid_statuses = %w[pending in_progress completed]
    valid_statuses.each do |status|
      @task.status = status
      assert @task.valid?, "#{status} should be valid"
    end
  end

  test "should reject invalid status values" do
    @task.status = "invalid_status"
    assert_not @task.valid?
    assert_includes @task.errors[:status], "invalid_status is not a valid status"
  end

  test "should allow blank status" do
    @task.status = nil
    assert @task.valid?
  end

  # Priority validations
  test "should accept valid priority values" do
    valid_priorities = %w[low normal high]
    valid_priorities.each do |priority|
      @task.priority = priority
      assert @task.valid?, "#{priority} should be valid"
    end
  end

  test "should reject invalid priority values" do
    @task.priority = "urgent"
    assert_not @task.valid?
    assert_includes @task.errors[:priority], "urgent is not a valid priority"
  end

  test "should allow blank priority" do
    @task.priority = nil
    assert @task.valid?
  end

  # Description validations
  test "should allow blank description" do
    @task.description = nil
    assert @task.valid?
  end

  test "should require description maximum 300 characters" do
    @task.description = "a" * 301
    assert_not @task.valid?
    assert_includes @task.errors[:description], "is too long (maximum is 300 characters)"
  end

  # Due date validations
  test "should allow blank due_date" do
    @task.due_date = nil
    assert @task.valid?
  end

  test "should allow future due_date" do
    @task.due_date = 1.day.from_now
    assert @task.valid?
  end

  test "should allow today as due_date" do
    @task.due_date = Time.current
    assert @task.valid?
  end

  test "should reject past due_date" do
    @task.due_date = 1.day.ago
    assert_not @task.valid?
    assert_includes @task.errors[:due_date], "cannot be in the past"
  end

  # ========== ASSOCIATION TESTS ==========

  test "should belong to user" do
    assert_respond_to @task, :user
  end

  test "should require user" do
    @task.user = nil
    assert_not @task.valid?
  end

  # ========== DEFAULT VALUES TESTS ==========

  test "should set default status to pending" do
    task = Task.new
    assert_equal "pending", task.status
  end

  test "should set default priority to normal" do
    task = Task.new
    assert_equal "normal", task.priority
  end

  # ========== HELPER METHODS TESTS ==========

  test "overdue? should return false when no due_date" do
    @task.due_date = nil
    assert_not @task.overdue?
  end

  test "overdue? should return false when due_date is in future" do
    @task.due_date = 1.day.from_now
    @task.status = "pending"
    assert_not @task.overdue?
  end

  test "overdue? should return true when due_date is past and not completed" do
    @task.due_date = 1.day.ago
    @task.status = "pending"
    # Skip validation to allow past date for testing
    @task.save(validate: false)
    assert @task.overdue?
  end

  test "overdue? should return false when due_date is past but task is completed" do
    @task.due_date = 1.day.ago
    @task.status = "completed"
    # Skip validation to allow past date for testing
    @task.save(validate: false)
    assert_not @task.overdue?
  end

  test "mark_completed should update status to completed" do
    @task.status = "pending"
    @task.save!
    @task.mark_completed
    assert_equal "completed", @task.reload.status
  end

  test "mark_completed should return true on success" do
    @task.status = "pending"
    @task.save!
    assert @task.mark_completed
  end
end
