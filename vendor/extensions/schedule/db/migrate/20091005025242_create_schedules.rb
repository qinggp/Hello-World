class CreateSchedules < ActiveRecord::Migration
  def self.up
    create_table :schedules do |t|
      t.date :due_date
      t.datetime :start_time
      t.datetime :end_time
      t.string :title
      t.text :detail
      t.boolean :public
      t.integer :user_id

      t.timestamps
    end
  end

  def self.down
    drop_table :schedules
  end
end
