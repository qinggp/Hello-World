class ChangeExpireDateTypeToDateFromInformation < ActiveRecord::Migration
  def self.up
    remove_column :information, :expire_date
    add_column :information, :expire_date, :date
  end

  def self.down
    remove_column :information, :expire_date
    add_column :information, :expire_date, :datetime
  end
end
