class CreateRamen < ActiveRecord::Migration[5.1]
  def change
    create_table :ramen do |t|
    	t.string :line_id
      t.datetime :scheduled_at
      t.string :remind_content
    end
  end
end
