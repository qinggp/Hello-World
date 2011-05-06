# == Schema Information
# Schema version: 20100227074439
#
# Table name: users_hobbies
#
#  id         :integer         not null, primary key
#  user_id    :integer
#  hobby_id   :integer
#  created_at :datetime
#  updated_at :datetime
#

class UsersHobby < ActiveRecord::Base
  belongs_to :user
  belongs_to :hobby
end
