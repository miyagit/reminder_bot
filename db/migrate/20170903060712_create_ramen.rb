class CreateRamen < ActiveRecord::Migration[5.1]
  def change
    create_table :ramen do |t|
    	t.string :user_id
      t.datetime :scheduled_at
    end
  end
end
