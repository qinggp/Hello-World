class ChangeColumnMessageSubject < ActiveRecord::Migration
  def self.up
    change_column :messages, :subject, :text
  end

  def self.down
    change_column :messages, :subject, :string
  end
end
