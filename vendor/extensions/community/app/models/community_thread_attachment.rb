# == Schema Information
# Schema version: 20100227074439
#
# Table name: community_thread_attachments
#
#  id         :integer         not null, primary key
#  image      :string(255)
#  position   :integer
#  thread_id  :integer
#  created_at :datetime
#  updated_at :datetime
#

class CommunityThreadAttachment < ActiveRecord::Base
  belongs_to :thread, :class_name => "CommunityThread", :foreign_key => "thread_id"

  file_column :image, :magick => {
    :versions => {:thumb =>  {:size => "100x100"}},
    :image_required => false
  }

  validates_file_format_of :image, :in => %w(jpg jpeg png gif txt csv pdf doc xls ppt zip lzh)
  validates_filesize_of :image, :in => 0..2.megabyte

  # トピック、マーカー、イベント、コメントの添付を取得するクエリ
  # ここでparent_thread_typeというカラムを作成し、レコードの情報を区分けしている。
  def self.topics_file_query(id = nil)
    if id
      sql =<<-SQL
        select id, image, 'CommunityThread' as parent_thread_type,
               thread_id, 0 as community_reply_id, created_at
        from community_thread_attachments
        where id = ?
        union all
        select a.id, a.image, 'CommunityReply' as parent_thread_type,
               community_replies.thread_id as thread_id, a.community_reply_id as thread_id, a.created_at
        from community_reply_attachments as a
        inner join community_replies on a.community_reply_id = community_replies.id
        where a.id = ?
        order by created_at desc
      SQL
      return [sql, id, id]
    else
      <<-SQL
        select id, image, 'CommunityThread' as parent_thread_type,
               thread_id, 0 as community_reply_id, created_at
        from community_thread_attachments
        union all
        select a.id, a.image, 'CommunityReply' as parent_thread_type,
               community_replies.thread_id as thread_id, a.community_reply_id as thread_id, a.created_at
        from community_reply_attachments as a
        inner join community_replies on a.community_reply_id = community_replies.id
        order by created_at desc
      SQL
    end
  end
end
