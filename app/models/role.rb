# == Schema Information
# Schema version: 20100227074439
#
# Table name: roles
#
#  id                :integer         not null, primary key
#  name              :string(40)
#  authorizable_type :string(40)
#  authorizable_id   :integer
#  created_at        :datetime
#  updated_at        :datetime
#

class Role < ActiveRecord::Base
  acts_as_authorization_role
end
