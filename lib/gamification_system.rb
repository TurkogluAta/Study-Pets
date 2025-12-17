# frozen_string_literal: true

module GamificationSystem
  # XP Constants
  BASE_XP_PER_MINUTE = 1
  GOAL_BONUS_MULTIPLIER = 2
  XP_PER_LEVEL = 100

  # Pet Energy Constants
  MAX_ENERGY = 100
  MIN_ENERGY = 0
  ENERGY_GAIN_PER_HOUR = 5  # 1 hour = +5 energy
  ENERGY_LOSS_PER_DAY = 20  # Daily decay

  # Pet Mood Options
  MOODS = %w[happy neutral sad].freeze

  class << self
    # Award XP and update stats when a study session is completed
    def award_session_rewards(user, study_session)
      return { success: false, message: "Session not completed" } unless study_session.completed?

      rewards = calculate_session_rewards(study_session)

      user.increment!(:experience_points, rewards[:xp])
      user.increment!(:total_study_time, study_session.actual_duration)

      # Check for level up
      new_level = calculate_level(user.experience_points)
      if new_level > user.level
        user.update!(level: new_level)
        rewards[:level_up] = true
        rewards[:new_level] = new_level
      end

      # Update pet energy based on session duration
      energy_gain = calculate_energy_gain(study_session.actual_duration)
      new_energy = [ user.pet_energy + energy_gain, MAX_ENERGY ].min
      user.update!(pet_energy: new_energy, pet_mood: determine_mood(new_energy))

      rewards
    end

    # Calculate XP rewards for a study session
    def calculate_session_rewards(study_session)
      base_xp = study_session.actual_duration * BASE_XP_PER_MINUTE

      bonus_xp = if study_session.goal_reached?
                   (study_session.actual_duration - study_session.duration) * GOAL_BONUS_MULTIPLIER
      else
                   0
      end

      total_xp = base_xp + bonus_xp

      {
        base_xp: base_xp,
        bonus_xp: bonus_xp,
        xp: total_xp,
        goal_reached: study_session.goal_reached?
      }
    end

    # Calculate user level based on total XP
    def calculate_level(experience_points)
      (experience_points / XP_PER_LEVEL) + 1
    end

    # Calculate and update user's study streak
    def calculate_streak(user)
      today = Date.current
      last_study = user.last_study_date

      if last_study.nil?
        user.update!(streak_days: 1, last_study_date: today)
        { streak: 1, streak_broken: false }
      elsif last_study == today
        { streak: user.streak_days, streak_broken: false }
      elsif last_study == today - 1.day
        user.increment!(:streak_days)
        user.update!(last_study_date: today)
        { streak: user.streak_days, streak_broken: false }
      else
        user.update!(streak_days: 1, last_study_date: today)
        { streak: 1, streak_broken: true }
      end
    end

    # Update pet mood and energy manually
    def update_pet_status(user, mood: nil, energy: nil)
      updates = {}

      if energy
        clamped_energy = [ [ energy, MIN_ENERGY ].max, MAX_ENERGY ].min
        updates[:pet_energy] = clamped_energy
        updates[:pet_mood] = determine_mood(clamped_energy) unless mood
      end

      updates[:pet_mood] = mood if mood && MOODS.include?(mood)

      user.update!(updates) if updates.any?
    end

    # Determine pet mood based on energy level
    def determine_mood(energy)
      case energy
      when 80..MAX_ENERGY
        "happy"
      when 40..79
        "neutral"
      else
        "sad"
      end
    end

    # Decay pet energy (call daily via cron/scheduler)
    def daily_energy_decay(user)
      new_energy = [ user.pet_energy - ENERGY_LOSS_PER_DAY, MIN_ENERGY ].max
      new_mood = determine_mood(new_energy)

      user.update!(pet_energy: new_energy, pet_mood: new_mood)

      { energy: new_energy, mood: new_mood }
    end

    # Get XP needed for next level
    def xp_to_next_level(user)
      current_level_xp = (user.level - 1) * XP_PER_LEVEL
      next_level_xp = user.level * XP_PER_LEVEL
      next_level_xp - user.experience_points
    end

    # Calculate energy gain based on study duration
    # 1 hour (60 minutes) = +5 energy
    def calculate_energy_gain(duration_minutes)
      (duration_minutes / 60.0 * ENERGY_GAIN_PER_HOUR).to_i
    end

    # Calculate days since last check
    def days_since_last_check(user)
      return 0 if user.last_checked_at.nil?

      last_check = user.last_checked_at.to_date
      today = Date.current

      (today - last_check).to_i
    end

    # Apply pending energy decay (lazy update)
    def apply_pending_decay(user)
      days_passed = days_since_last_check(user)

      return { days_passed: 0 } if days_passed.zero?

      # Apply accumulated decay
      total_energy_loss = days_passed * ENERGY_LOSS_PER_DAY
      new_energy = [ user.pet_energy - total_energy_loss, MIN_ENERGY ].max
      new_mood = determine_mood(new_energy)

      user.update!(
        pet_energy: new_energy,
        pet_mood: new_mood,
        last_checked_at: Time.current
      )

      # Check streak
      streak_result = check_and_reset_streak(user)

      {
        days_passed: days_passed,
        energy_lost: total_energy_loss,
        new_energy: new_energy,
        new_mood: new_mood,
        streak_broken: streak_result[:streak_broken]
      }
    end

    # Check and reset streak if broken (strict: 1 day miss = broken)
    def check_and_reset_streak(user)
      last_study = user.last_study_date
      today = Date.current

      # If last study was before yesterday, streak is broken
      if last_study.nil? || last_study < today - 1.day
        user.update!(streak_days: 0) if user.streak_days > 0
        return { streak_broken: true, streak: 0 }
      end

      { streak_broken: false, streak: user.streak_days }
    end
  end
end
