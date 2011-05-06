# == Schema Information
# Schema version: 20100227074439
#
# Table name: message_attachment_associations
#
#  id                    :integer         not null, primary key
#  message_id            :integer
#  message_attachment_id :integer
#  created_at            :datetime
#  updated_at            :datetime
#

class MessageAttachmentAssociation < ActiveRecord::Base
  belongs_to :message
  belongs_to :message_attachment
end
