class StudySession < ApplicationRecord
  # == ASSOCIATIONS ==
  belongs_to :user

  # == VALIDATIONS ==
  # title: required, 3–100 chars
  validates :title,
            presence: true,
            length: { minimum: 3, maximum: 100 }

  # start_time: required
  validates :start_time, presence: true

  # duration: required (target minutes)
  validates :duration,
            numericality: { greater_than: 0 },
            presence: true

  # focus_rating: optional, must be 1–5 if given
  validates :focus_rating,
            inclusion: { in: 1..5, message: "must be between 1 and 5" },
            allow_nil: true

  # notes: optional, but max 300 characters
  validates :notes,
            length: { maximum: 300,
                      message: "is too long (maximum is 300 characters)" },
            allow_blank: true

  # == CUSTOM VALIDATIONS ==
  # Ensure end_time is after start_time
  validate :end_time_after_start_time, if: -> { end_time.present? }

  # == DEFAULTS ==
  # Set start_time to current time if not provided
  before_validation :set_start_time, on: :create

  # == CALLBACKS ==
  before_save :finish_session, if: -> { end_time.present? && actual_duration.blank? }

  # == HELPER METHODS ==
  # Converts actual duration (in minutes) to hours
  def actual_duration_in_hours
    (actual_duration.to_i / 60.0).round(1)
  end

  # Checks if goal duration reached (used by GamificationSystem library)
  def goal_reached?
    actual_duration.present? && duration.present? && actual_duration >= duration
  end

  private

  # When session ends: calculate actual_duration and mark as completed
  def finish_session
    if start_time.present?
      self.actual_duration = ((end_time - start_time) / 60).to_i
      self.completed = true
    end
  end

  # Set default start_time to current time when creating a new session
  def set_start_time
    self.start_time ||= Time.current
  end

  # Validate that end_time is after start_time
  def end_time_after_start_time
    if start_time.present? && end_time <= start_time
      errors.add(:end_time, "must be after start time")
    end
  end
end
