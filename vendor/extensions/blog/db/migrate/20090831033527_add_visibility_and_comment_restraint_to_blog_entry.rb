class AddVisibilityAndCommentRestraintToBlogEntry < ActiveRecord::Migration
  def self.up
    add_column :blog_entries, :visibility, :integer
    add_column :blog_entries, :comment_restraint, :integer
  end

  def self.down
    remove_column :blog_entries, :comment_restraint
    remove_column :blog_entries, :visibility
  end
end
