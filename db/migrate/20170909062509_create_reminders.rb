class CreateReminders < ActiveRecord::Migration[5.1]
  def change
    create_table :reminders do |t|
    	t.string :line_id
      t.datetime :scheduled_at
      t.string :remind_content
      t.timestamps
    end
  end
end
