class AddEmailAndUserNameAnonymousToBlogComments < ActiveRecord::Migration
  def self.up
    add_column :blog_comments, :email, :string
    add_column :blog_comments, :user_name, :string
    add_column :blog_comments, :anonymous, :boolean
  end

  def self.down
    remove_column :blog_comments, :user_name
    remove_column :blog_comments, :email
    remove_column :blog_comments, :anonymous
  end
end
