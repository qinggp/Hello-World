class AddMessageNoticeAcceptableToPreferences < ActiveRecord::Migration
  def self.up
    add_column :preferences, :message_notice_acceptable, :boolean, :default => true
  end

  def self.down
    remove_column :preferences, :message_notice_acceptable
  end
end
