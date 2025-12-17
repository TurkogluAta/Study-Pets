class AddLastCheckedAtToUsers < ActiveRecord::Migration[8.1]
  def change
    add_column :users, :last_checked_at, :datetime

    # Set current time for existing users
    reversible do |dir|
      dir.up do
        User.update_all(last_checked_at: Time.current)
      end
    end
  end
end
