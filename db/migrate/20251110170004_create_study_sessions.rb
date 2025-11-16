class CreateStudySessions < ActiveRecord::Migration[8.1]
  def change
    create_table :study_sessions do |t|
      t.references :user, null: false, foreign_key: true
      t.string :title, null: false
      t.datetime :start_time, null: false
      t.datetime :end_time
      t.integer :duration, null: false
      t.integer :actual_duration
      t.integer :focus_rating
      t.boolean :completed, default: false
      t.text :notes
      t.timestamps
    end
  end
end
