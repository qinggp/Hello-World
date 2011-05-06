class CreatePages < ActiveRecord::Migration
  def self.up
    create_table :pages do |t|
      t.string :page_id
      t.text :title
      t.text :body

      t.timestamps
    end
    add_index :pages, :page_id
    add_index :pages, :title
  end

  def self.down
    remove_index :pages, :page_id
    remove_index :pages, :title

    drop_table :pages
  end
end
