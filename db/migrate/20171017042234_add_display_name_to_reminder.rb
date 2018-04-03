class AddDisplayNameToReminder < ActiveRecord::Migration[5.1]
  def change
    add_column :reminders, :display_name, :string, after: :line_id
  end
end
