# == Schema Information
# Schema version: 20100227074439
#
# Table name: blog_comments
#
#  id            :integer         not null, primary key
#  user_id       :integer
#  blog_entry_id :integer
#  body          :text
#  created_at    :datetime
#  updated_at    :datetime
#  email         :string(255)
#  user_name     :string(255)
#  anonymous     :boolean
#
# ブログに対するコメント
class BlogComment < ActiveRecord::Base
  belongs_to :user
  belongs_to :blog_entry, :counter_cache => true

  validates_presence_of :body
  validates_presence_of :user_id, :if => Proc.new{|comment| !comment.anonymous? }
  validates_presence_of :user_name, :if => Proc.new{|comment| comment.anonymous? }
  with_options :if => Proc.new{|comment| comment.anonymous? }, :allow_blank => true, :allow_nil => true do |anonymous|
    anonymous.validates_length_of :email, :within => 6..100
    anonymous.validates_format_of :email, :with => Authentication.email_regex,
                                          :message => Authentication.bad_email_message
  end

  named_scope :by_visible, lambda{|user|
    {:conditions => by_visible_for_user_condition(user), :include => :blog_entry}
  }
  named_scope :by_entry_user, lambda{|user|
    {:conditions => ["blog_entries.user_id = ?", user.id], :include => :blog_entry}
  }
  named_scope :by_other_entry_user, lambda{|user|
    {:conditions => ["blog_entries.user_id != ?", user.id], :include => :blog_entry}
  }
  named_scope :recents_by_entries, lambda {|limit, ago_days|
    {:conditions => ["blog_comments.created_at > ?", ago_days],
      :order => "blog_comments.created_at DESC", :limit => limit}
  }
  named_scope :by_other_user_comment, lambda {|user|
    {:conditions => ["blog_comments.user_id != ? OR blog_comments.user_id IS NULL", user.id]}
  }

  @@default_index_order = 'blog_comments.created_at DESC'
  cattr_reader :default_index_order

  # 自分のブログへの最近のコメント一覧取得
  def self.recents_my_blog(my, visit_user, limit=nil, ago_days=30.day.ago, myself=false)
    comments = by_visible(visit_user).by_entry_user(my)
    if myself
      comments.recents_by_entries(limit, ago_days)
    else
      comments.by_other_user_comment(my).recents_by_entries(limit, ago_days)
    end
  end

  # 自分が書き込んだ最近のコメント
  # ただし、自分のブログへ自分が書き込んだコメントは除外する
  # また、自分が書き込んだコメントの作成日でソートするのではなく、自分がコメントしたブログの最新コメント（他者がコメントしたものも含む）順でソートする
  #
  # NOTE: blog_entry_idに重複がなく、limitを指定したレコードを取得するために find_by_sql を使用している。
  def self.recents_my_comment(my, visit_user, limit=nil, ago_days=30.day.ago)
    values = by_visible_for_user_condition(visit_user)
    wheres = [values.shift]

    wheres << "my_comments.user_id = ?"
    values << my.id

    wheres << "blog_entries.user_id != ?"
    values << my.id

    wheres << "my_comments.created_at > ?"
    values << ago_days

    wheres << "my_comments.blog_entry_id = blog_entries.id"

    where = sanitize_sql([wheres.map{|i| "(#{i})" }.join(" AND ")] + values)

    group_by = "blog_comments.blog_entry_id, blog_entries.title, blog_entries.blog_comments_count, users.name, blog_entries.user_id"
    select = "#{group_by}, MAX(blog_comments.created_at) AS created_at"
    from = "(blog_entries INNER JOIN blog_comments ON blog_entries.id = blog_comments.blog_entry_id) INNER JOIN users ON blog_entries.user_id = users.id, blog_comments AS my_comments"
    appedix = "ORDER BY created_at DESC " + (limit.nil? ? "" : "LIMIT #{limit}")

    return self.find_by_sql("select #{select} from #{from} WHERE #{where} GROUP BY #{group_by} #{appedix}")
  end

  # デフォルト属性値
  def self.default_attributes(attr, current_user, entry)
    attr_dup = attr.dup
    attr_dup[:blog_entry_id] = entry.id
    if current_user
      attr_dup[:user_id] = current_user.id
      attr_dup[:anonymous] = false
    else
      attr_dup[:user_id] = nil
      attr_dup[:anonymous] = true
    end
    return attr_dup
  end

  # 修正可能か？
  def editable?(current_user)
    return false if self.anonymous?
    return current_user.try(:id) == user_id
  end

  # 削除可能か？
  def deletable?(current_user)
    return true if current_user.try(:id) == blog_entry.user_id
    return true if current_user.try(:has_role?, :blog_entry_author, blog_entry)
    return editable?(current_user)
  end

  # コメントしたユーザ名
  def comment_user_name
    return user_name if self.anonymous?
    return user.name
  end

  private

  def self.by_visible_for_user_condition(user)
    return BlogEntry.by_visible_for_user_condition(user, false) if user
    return ["blog_entries.visibility = ?", BlogPreference::VISIBILITIES[:publiced]]
  end
end
