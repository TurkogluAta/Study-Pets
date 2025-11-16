class CreateUsers < ActiveRecord::Migration[8.1]
  def change
    create_table :users do |t|
      t.string :username
      t.string :email
      t.string :password_digest
      t.string :name
      t.integer :total_study_time
      t.integer :streak_days
      t.date :last_study_date
      t.string :pet_name
      t.string :pet_type
      t.string :pet_mood
      t.integer :pet_energy
      t.integer :level
      t.integer :experience_points

      t.timestamps
    end
    add_index :users, :username, unique: true
    add_index :users, :email, unique: true
  end
end
