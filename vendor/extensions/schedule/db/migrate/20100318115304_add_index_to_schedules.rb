class AddIndexToSchedules < ActiveRecord::Migration
  def self.up
    add_index :schedules, :due_date
    add_index :schedules, :public
  end

  def self.down
    remove_index :schedules, :due_date
    remove_index :schedules, :public
  end
end
