class Task < ApplicationRecord
  # == ASSOCIATIONS ==
  # Each task belongs to a specific user.
  belongs_to :user

  # == VALIDATIONS ==
  # title: required, 3–100 chars
  validates :title,
            presence: true,
            length: { minimum: 3, maximum: 100 }

  # status: optional, but if present must be one of these values.
  validates :status,
            inclusion: { in: %w[pending in_progress completed],
                         message: "%{value} is not a valid status" },
            allow_blank: true

  # priority: optional, but must be one of these values if given.
  validates :priority,
            inclusion: { in: %w[low normal high],
                         message: "%{value} is not a valid priority" },
            allow_blank: true

  # description: optional, maximum 300 characters
  validates :description,
            length: { maximum: 300,
                      message: "is too long (maximum is 300 characters)" },
            allow_blank: true

  # due_date: optional but if provided, must be a valid datetime.
  validate :due_date_cannot_be_in_the_past, if: -> { due_date.present? }

  # == DEFAULTS ==
  # Set default status and priority for new tasks
  after_initialize :set_task_defaults, if: :new_record?

  # == HELPER METHODS ==
  # Returns true if the task deadline has passed and it’s not completed.
  def overdue?
    due_date.present? && due_date < Time.current && status != "completed"
  end

  # Marks a task as completed and updates the status automatically.
  def mark_completed
    update(status: "completed")
  end

  private

  # Prevents creating a task with a past due date
  def due_date_cannot_be_in_the_past
    if due_date.to_date < Date.current
      errors.add(:due_date, "cannot be in the past")
    end
  end

  # Set default values for status and priority
  def set_task_defaults
    self.status ||= "pending"
    self.priority ||= "normal"
  end
end
