class CreateJobs < ActiveRecord::Migration
  def self.up
    create_table :jobs do |t|
      t.string :name
      t.string :position
    end
    add_index :jobs, :position, :unique => true
  end

  def self.down
    drop_table :jobs
  end
end
