# == Schema Information
# Schema version: 20100227074439
#
# Table name: sns_themes
#
#  id         :integer         not null, primary key
#  name       :string(255)
#  human_name :string(255)
#

class SnsTheme < ActiveRecord::Base
end
