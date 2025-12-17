require "test_helper"

class StudySessionTest < ActiveSupport::TestCase
  # Setup
  def setup
    @session = study_sessions(:one)
  end

  # ========== VALIDATION TESTS ==========

  test "should be valid with valid attributes" do
    assert @session.valid?
  end

  # Title validations
  test "should require title" do
    @session.title = nil
    assert_not @session.valid?
    assert_includes @session.errors[:title], "can't be blank"
  end

  test "should require title minimum 3 characters" do
    @session.title = "ab"
    assert_not @session.valid?
  end

  test "should require title maximum 100 characters" do
    @session.title = "a" * 101
    assert_not @session.valid?
  end

  # Start time validations
  test "should require start_time" do
    @session.start_time = nil
    assert_not @session.valid?
    assert_includes @session.errors[:start_time], "can't be blank"
  end

  # Duration validations
  test "should require duration" do
    @session.duration = nil
    assert_not @session.valid?
    assert_includes @session.errors[:duration], "can't be blank"
  end

  test "should require duration greater than 0" do
    @session.duration = 0
    assert_not @session.valid?
    assert_includes @session.errors[:duration], "must be greater than 0"
  end

  test "should reject negative duration" do
    @session.duration = -5
    assert_not @session.valid?
  end

  test "should accept positive duration" do
    @session.duration = 30
    assert @session.valid?
  end

  # Focus rating validations
  test "should allow nil focus_rating" do
    @session.focus_rating = nil
    assert @session.valid?
  end

  test "should accept valid focus_rating values" do
    (1..5).each do |rating|
      @session.focus_rating = rating
      assert @session.valid?, "#{rating} should be valid"
    end
  end

  test "should reject focus_rating less than 1" do
    @session.focus_rating = 0
    assert_not @session.valid?
    assert_includes @session.errors[:focus_rating], "must be between 1 and 5"
  end

  test "should reject focus_rating greater than 5" do
    @session.focus_rating = 6
    assert_not @session.valid?
    assert_includes @session.errors[:focus_rating], "must be between 1 and 5"
  end

  # Notes validations
  test "should allow blank notes" do
    @session.notes = nil
    assert @session.valid?
  end

  test "should require notes maximum 300 characters" do
    @session.notes = "a" * 301
    assert_not @session.valid?
    assert_includes @session.errors[:notes], "is too long (maximum is 300 characters)"
  end

  # End time validations
  test "should reject end_time before start_time" do
    @session.start_time = Time.current
    @session.end_time = 1.hour.ago
    assert_not @session.valid?
    assert_includes @session.errors[:end_time], "must be after start time"
  end

  test "should reject end_time equal to start_time" do
    time = Time.current
    @session.start_time = time
    @session.end_time = time
    assert_not @session.valid?
    assert_includes @session.errors[:end_time], "must be after start time"
  end

  test "should accept end_time after start_time" do
    @session.start_time = Time.current
    @session.end_time = 1.hour.from_now
    assert @session.valid?
  end

  # ========== ASSOCIATION TESTS ==========

  test "should belong to user" do
    assert_respond_to @session, :user
  end

  test "should require user" do
    @session.user = nil
    assert_not @session.valid?
  end

  # ========== CALLBACK TESTS ==========

  test "should set default start_time on create" do
    session = StudySession.new(
      user: users(:one),
      title: "Test Session",
      duration: 30
    )
    assert_nil session.start_time
    session.valid? # Triggers before_validation
    assert_not_nil session.start_time
  end

  test "should not override provided start_time" do
    custom_time = 1.hour.ago
    session = StudySession.new(
      user: users(:one),
      title: "Test Session",
      duration: 30,
      start_time: custom_time
    )
    session.valid?
    assert_equal custom_time.to_i, session.start_time.to_i
  end

  test "should calculate actual_duration when end_time is set" do
    session = StudySession.create!(
      user: users(:one),
      title: "Test Session",
      duration: 30,
      start_time: 2.hours.ago
    )

    session.end_time = 1.hour.ago
    session.save!

    assert_equal 60, session.actual_duration
  end

  test "should mark session as completed when end_time is set" do
    session = StudySession.create!(
      user: users(:one),
      title: "Test Session",
      duration: 30,
      start_time: 1.hour.ago
    )

    assert_not session.completed

    session.update!(end_time: Time.current)

    assert session.completed
  end

  # ========== HELPER METHODS TESTS ==========

  test "actual_duration_in_hours should convert minutes to hours" do
    @session.actual_duration = 60
    assert_equal 1.0, @session.actual_duration_in_hours

    @session.actual_duration = 90
    assert_equal 1.5, @session.actual_duration_in_hours

    @session.actual_duration = 45
    assert_equal 0.8, @session.actual_duration_in_hours
  end

  test "actual_duration_in_hours should handle nil" do
    @session.actual_duration = nil
    assert_equal 0.0, @session.actual_duration_in_hours
  end

  test "goal_reached? should return false when actual_duration is nil" do
    @session.actual_duration = nil
    @session.duration = 30
    assert_not @session.goal_reached?
  end

  test "goal_reached? should return false when duration is nil" do
    @session.actual_duration = 30
    @session.duration = nil
    assert_not @session.goal_reached?
  end

  test "goal_reached? should return false when actual_duration is less than duration" do
    @session.actual_duration = 20
    @session.duration = 30
    assert_not @session.goal_reached?
  end

  test "goal_reached? should return true when actual_duration equals duration" do
    @session.actual_duration = 30
    @session.duration = 30
    assert @session.goal_reached?
  end

  test "goal_reached? should return true when actual_duration exceeds duration" do
    @session.actual_duration = 45
    @session.duration = 30
    assert @session.goal_reached?
  end

  # ========== INTEGRATION TESTS ==========

  test "complete session workflow" do
    # Create session
    session = StudySession.create!(
      user: users(:one),
      title: "Complete Workflow Test",
      duration: 30
    )

    # Verify initial state
    assert_not_nil session.start_time
    assert_nil session.end_time
    assert_nil session.actual_duration
    assert_not session.completed

    # Complete session after 45 minutes
    session.update!(
      end_time: session.start_time + 45.minutes,
      focus_rating: 4
    )

    # Verify final state
    assert_equal 45, session.actual_duration
    assert session.completed
    assert_equal 4, session.focus_rating
    assert session.goal_reached?
  end
end
