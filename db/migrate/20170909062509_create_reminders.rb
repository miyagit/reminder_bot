class CreateReminders < ActiveRecord::Migration[5.1]
  def change
    create_table :reminders do |t|
    	t.string :line_id
      t.datetime :scheduled_at
      t.string :remind_content
      t.integer :remind_status, default: 0
      t.timestamps
    end
  end
end
