class CreateTasks < ActiveRecord::Migration[8.1]
  def change
    create_table :tasks do |t|
      t.references :user, null: false, foreign_key: true
      t.string :title
      t.datetime :due_date
      t.string :status
      t.string :priority
      t.text :description

      t.timestamps
    end
  end
end
