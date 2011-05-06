# == Schema Information
# Schema version: 20100227074439
#
# Table name: message_attachments
#
#  id         :integer         not null, primary key
#  image      :string(255)
#  position   :integer
#  created_at :datetime
#  updated_at :datetime
#

class MessageAttachment < ActiveRecord::Base
  has_many :message_attachment_associations
  has_many :messages, :through => :message_attachment_associations

  file_column :image, :magick => {
    :versions => {:thumb =>  {:size => "100x100"}},
    :image_required => false
  }

  validates_file_format_of :image, :in => %w(jpg jpeg png gif txt csv pdf doc xls ppt zip lzh)
  validates_filesize_of :image, :in => 0..1.megabyte

  # userが添付ファイルを見る権限があるかどうか
  def viewable?(user)
    self.messages.map{|m| [m.sender_id, m.receiver_id]}.flatten.uniq.include?(user.id)
  end
end
