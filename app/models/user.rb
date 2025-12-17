class User < ApplicationRecord
  # == ASSOCIATIONS ==
  has_many :tasks, dependent: :destroy
  has_many :study_sessions, dependent: :destroy

  # == AUTHENTICATION ==
  # Adds password hashing and authentication using bcrypt.
  has_secure_password

  # == NORMALIZATION ==
  # Clean up fields that affect uniqueness before validation.
  before_validation :normalize_identity_fields

  # == DEFAULTS ==
  # Set initial values for new users (gamification fields)
  after_initialize :set_defaults, if: :new_record?

  # == VALIDATIONS ==
  # username: required, unique (case-insensitive), min 3 chars
  validates :username,
            presence: true,
            length: { minimum: 3, maximum: 50 },
            uniqueness: { case_sensitive: false }

  # email: required, unique (case-insensitive), must look like a real email
  validates :email,
            presence: true,
            format: { with: /\A[^@\s]+@[^@\s]+\z/, message: "is invalid" },
            uniqueness: { case_sensitive: false }

  # name: required, 3–50 chars
  validates :name,
            presence: true,
            length: { minimum: 3, maximum: 50 }

  # pet_name: required, 3–30 chars
  validates :pet_name,
            presence: true,
            length: { minimum: 3, maximum: 30 }

  # pet_type: required, only cat or dog
  validates :pet_type,
            presence: true,
            inclusion: { in: %w[cat dog],
                         message: "%{value} is not a valid pet type" }

  # Override JSON serialization to exclude sensitive data
  def as_json(options = {})
    super(options.merge(except: [ :password_digest ]))
  end

  private

  # Only normalize fields that matter for validation and uniqueness
  def normalize_identity_fields
    self.username = username.to_s.strip
    self.email    = email.to_s.strip.downcase
    self.pet_type = pet_type.to_s.strip.downcase
  end

  # Set default values for gamification system
  def set_defaults
    self.level ||= 1
    self.experience_points ||= 0
    self.pet_mood ||= "happy"
    self.pet_energy ||= 100
    self.streak_days ||= 0
    self.total_study_time ||= 0
    self.last_checked_at ||= Time.current
  end
end
