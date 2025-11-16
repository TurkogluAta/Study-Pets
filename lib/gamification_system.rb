# frozen_string_literal: true

module GamificationSystem
  # XP Constants
  BASE_XP_PER_MINUTE = 1
  GOAL_BONUS_MULTIPLIER = 2
  XP_PER_LEVEL = 100

  # Pet Energy Constants
  MAX_ENERGY = 100
  MIN_ENERGY = 0
  ENERGY_GAIN_PER_SESSION = 10
  ENERGY_LOSS_PER_DAY = 5

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

      # Update pet energy
      new_energy = [ user.pet_energy + ENERGY_GAIN_PER_SESSION, MAX_ENERGY ].min
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
      when 70..MAX_ENERGY
        "happy"
      when 30..69
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
  end
end
