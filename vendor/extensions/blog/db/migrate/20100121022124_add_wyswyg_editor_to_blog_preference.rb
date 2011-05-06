class AddWyswygEditorToBlogPreference < ActiveRecord::Migration
  def self.up
    add_column :blog_preferences, :wyswyg_editor, :boolean, :default => false
  end

  def self.down
    remove_column :blog_preferences, :wyswyg_editor
  end
end
