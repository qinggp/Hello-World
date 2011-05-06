class CreateUsersHobbies < ActiveRecord::Migration
  def self.up
    create_table :users_hobbies do |t|
      t.integer :user_id
      t.integer :hobby_id

      t.timestamps
    end
  end

  def self.down
    drop_table :users_hobbies
  end
end
