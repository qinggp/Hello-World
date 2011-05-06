class CreateSnsThemes < ActiveRecord::Migration
  def self.up
    create_table :sns_themes do |t|
      t.string :name
      t.string :human_name
    end
  end

  def self.down
    drop_table :sns_themes
  end
end
