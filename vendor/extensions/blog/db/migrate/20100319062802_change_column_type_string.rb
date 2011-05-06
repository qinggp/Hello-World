class ChangeColumnTypeString < ActiveRecord::Migration
  def self.up
    change_column :blog_preferences, :rss_url, :text
    change_column :blog_preferences, :title, :text

    change_column :blog_entries, :title, :text

    change_column :blog_comments, :user_name, :text
    change_column :blog_comments, :email, :text
  end

  def self.down
    change_column :blog_preferences, :rss_url, :string
    change_column :blog_preferences, :title, :string

    change_column :blog_entries, :title, :string

    change_column :blog_comments, :user_name, :string
    change_column :blog_comments, :email, :string
  end
end
