class AddEmailPostVisibilityToBlogPreferences < ActiveRecord::Migration
  def self.up
    add_column :blog_preferences, :email_post_visibility, :integer
  end

  def self.down
    remove_column :blog_preferences, :email_post_visibility
  end
end
