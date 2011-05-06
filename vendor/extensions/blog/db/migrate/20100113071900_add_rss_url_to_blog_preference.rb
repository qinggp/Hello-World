class AddRssUrlToBlogPreference < ActiveRecord::Migration
  def self.up
    add_column :blog_preferences, :rss_url, :string
  end

  def self.down
    remove_column :blog_preferences, :rss_url
  end
end
