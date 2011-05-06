# == Schema Information
# Schema version: 20100227074439
#
# Table name: blog_attachments
#
#  id            :integer         not null, primary key
#  image         :string(255)
#  blog_entry_id :integer
#  position      :integer
#  created_at    :datetime
#  updated_at    :datetime
#

class BlogAttachment < ActiveRecord::Base
  belongs_to :blog_entry

  file_column :image,
              :magick => {
                :versions => {
                  :thumb => "40x40",
                  :medium => "120x120"},
              :image_required => false
  }

  attr_accessible :position, :image, :image_temp

  validates_file_format_of :image, :in => %w(jpg jpeg png gif txt pdf doc xls ppt zip lzh wma)
  validates_uniqueness_of :position, :scope => :blog_entry_id
  validates_filesize_of :image, :in => 0..3.megabyte
end
