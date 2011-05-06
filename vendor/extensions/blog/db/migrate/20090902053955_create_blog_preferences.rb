class CreateBlogPreferences < ActiveRecord::Migration
  def self.up
    create_table :blog_preferences do |t|
      t.integer :preference_id
      t.integer :visibility
      t.string :title
      t.integer :basic_color
      t.boolean :comment_notice_acceptable

      t.timestamps
    end
  end

  def self.down
    drop_table :blog_preferences
  end
end
