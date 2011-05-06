# == Schema Information
# Schema version: 20100227074439
#
# Table name: community_reply_attachments
#
#  id                 :integer         not null, primary key
#  image              :string(255)
#  position           :integer
#  community_reply_id :integer
#  created_at         :datetime
#  updated_at         :datetime
#

class CommunityReplyAttachment < ActiveRecord::Base
  belongs_to :reply, :class_name => "CommunityReply", :foreign_key => "community_reply_id"

  file_column :image, :magick => {
    :versions => {:thumb =>  {:size => "100x100"}},
    :image_required => false
  }

  validates_file_format_of :image, :in => %w(jpg jpeg png gif txt csv pdf doc xls ppt zip lzh)
  validates_filesize_of :image, :in => 0..2.megabyte
end
