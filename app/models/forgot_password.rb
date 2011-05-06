# == Schema Information
# Schema version: 20100227074439
#
# Table name: forgot_passwords
#
#  id              :integer         not null, primary key
#  user_id         :integer
#  reset_code      :string(255)
#  expiration_date :datetime
#  created_at      :datetime
#  updated_at      :datetime
#

require 'digest/sha1'

class ForgotPassword < ActiveRecord::Base
  belongs_to :user
  attr_accessor :email
  validates_presence_of :email
  validates_format_of :email, :unless => Proc.new{|p|p.email.blank?}, :with => /^([^@\s]+)@((?:[-a-z0-9]+\.)+[a-z]{2,})$/i, :message => 'の形式が不正です。'
  validates_presence_of :user, :unless => Proc.new{|p|p.errors.on(:email)}, :message => 'をもつユーザは存在しません。'

  attr_protected :user_id, :reset_code, :expiration_date

  protected
  def before_create
    self.reset_code = Digest::SHA1.hexdigest(Time.now.to_s.split(//).sort_by {rand}.join )
    self.expiration_date = 2.weeks.from_now
  end
end
