require "test_helper"

class GamificationSystemTest < ActiveSupport::TestCase
  setup do
    @user = users(:one)
  end

  # ========== SESSION REWARDS TESTS ==========

  test "should award session rewards for completed session" do
    session = @user.study_sessions.create!(
      title: "Test",
      duration: 60,
      start_time: 2.hours.ago,
      end_time: 1.hour.ago,
      completed: true
    )

    initial_xp = @user.experience_points

    rewards = GamificationSystem.award_session_rewards(@user, session)

    assert_equal 60, rewards[:xp]
    @user.reload
    assert_equal initial_xp + 60, @user.experience_points
  end

  test "should award bonus XP when exceeding goal" do
    session = @user.study_sessions.create!(
      title: "Bonus Test",
      duration: 30,
      start_time: 90.minutes.ago,
      end_time: Time.current,
      completed: true
    )

    rewards = GamificationSystem.award_session_rewards(@user, session)

    # Base: 90, Bonus: 120, Total: 210
    assert_equal 210, rewards[:xp]
  end

  test "should trigger level up when threshold reached" do
    @user.update!(experience_points: 95, level: 1)

    session = @user.study_sessions.create!(
      title: "Level Up",
      duration: 10,
      start_time: 10.minutes.ago,
      end_time: Time.current,
      completed: true
    )

    rewards = GamificationSystem.award_session_rewards(@user, session)

    assert rewards[:level_up]
    assert_equal 2, rewards[:new_level]
  end

  # ========== LEVEL CALCULATION TESTS ==========

  test "should calculate level correctly" do
    assert_equal 1, GamificationSystem.calculate_level(0)
    assert_equal 1, GamificationSystem.calculate_level(99)
    assert_equal 2, GamificationSystem.calculate_level(100)
    assert_equal 2, GamificationSystem.calculate_level(199)
    assert_equal 10, GamificationSystem.calculate_level(900)
  end

  # ========== STREAK TESTS ==========

  test "should start streak at 1 for first session" do
    @user.update!(streak_days: 0, last_study_date: nil)

    result = GamificationSystem.calculate_streak(@user)

    assert_equal 1, result[:streak]
    assert_equal false, result[:streak_broken]
  end

  test "should increment streak for consecutive days" do
    @user.update!(streak_days: 3, last_study_date: Date.current - 1.day)

    result = GamificationSystem.calculate_streak(@user)

    assert_equal 4, result[:streak]
    assert_equal false, result[:streak_broken]
  end

  test "should break streak when missing days" do
    @user.update!(streak_days: 10, last_study_date: Date.current - 3.days)

    result = GamificationSystem.calculate_streak(@user)

    assert_equal 1, result[:streak]
    assert_equal true, result[:streak_broken]
  end

  # ========== MOOD TESTS ==========

  test "should determine mood based on energy" do
    assert_equal "happy", GamificationSystem.determine_mood(80)
    assert_equal "happy", GamificationSystem.determine_mood(100)
    assert_equal "neutral", GamificationSystem.determine_mood(50)
    assert_equal "neutral", GamificationSystem.determine_mood(79)
    assert_equal "sad", GamificationSystem.determine_mood(0)
    assert_equal "sad", GamificationSystem.determine_mood(39)
  end

  # ========== ENERGY TESTS ==========

  test "should calculate energy gain correctly" do
    assert_equal 5, GamificationSystem.calculate_energy_gain(60)
    assert_equal 10, GamificationSystem.calculate_energy_gain(120)
    assert_equal 2, GamificationSystem.calculate_energy_gain(30)
  end

  test "should apply daily energy decay" do
    @user.update!(pet_energy: 80, pet_mood: "happy")

    result = GamificationSystem.daily_energy_decay(@user)

    assert_equal 60, result[:energy]
    assert_equal "neutral", result[:mood]
  end

  test "should not decay energy below minimum" do
    @user.update!(pet_energy: 10)

    result = GamificationSystem.daily_energy_decay(@user)

    assert_equal 0, result[:energy]
    assert_equal "sad", result[:mood]
  end

  # ========== XP TO NEXT LEVEL ==========

  test "should calculate XP to next level" do
    @user.update!(level: 1, experience_points: 0)
    assert_equal 100, GamificationSystem.xp_to_next_level(@user)

    @user.update!(level: 1, experience_points: 50)
    assert_equal 50, GamificationSystem.xp_to_next_level(@user)

    @user.update!(level: 2, experience_points: 150)
    assert_equal 50, GamificationSystem.xp_to_next_level(@user)
  end
end
