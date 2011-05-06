class CreateSnsLinkages < ActiveRecord::Migration
  def self.up
    create_table :sns_linkages do |t|
      t.string :key
      t.integer :user_id

      t.timestamps
    end
  end

  def self.down
    drop_table :sns_linkages
  end
end
