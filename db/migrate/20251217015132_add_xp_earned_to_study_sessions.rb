class AddXpEarnedToStudySessions < ActiveRecord::Migration[8.1]
  def change
    add_column :study_sessions, :xp_earned, :integer
  end
end
