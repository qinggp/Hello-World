# == Schema Information
# Schema version: 20100227074439
#
# Table name: community_threads
#
#  id                        :integer         not null, primary key
#  title                     :string(255)
#  content                   :text
#  event_date                :date
#  event_date_note           :string(255)
#  place                     :string(255)
#  latitude                  :decimal(9, 6)
#  longitude                 :decimal(9, 6)
#  zoom                      :integer
#  user_id                   :integer
#  community_id              :integer
#  public                    :boolean
#  community_map_category_id :integer
#  type                      :string(255)
#  created_at                :datetime
#  updated_at                :datetime
#  lastposted_at             :datetime
#

class CommunityTopic < CommunityThread
  @@presence_of_columns = [:title, :content]
  validates_presence_of @@presence_of_columns
  cattr_reader :presence_of_columns

  # トピック、マーカー、イベント、コメントの書き込みを取得するクエリL
  def self.topics_write_query(id = nil)
    if id
      sql =<<-SQL
        select id ,title, content, user_id, created_at, community_id, 0 as thread_id, 'CommunityThread' as parent_thread_type, 'CommunityTopic' AS kind   from community_threads
        where type = 'CommunityTopic' AND id = ? union all

        select id ,title, content, user_id, created_at, community_id, 0 as thread_id, 'CommunityThread' as parent_thread_type, 'CommunityEvent' AS kind from community_threads
        where type = 'CommunityEvent' AND id = ? union all

        select id, title, content, user_id, created_at, community_id, 0 as thread_id, 'CommunityThread' as parent_thread_type, 'CommunityMarker' AS kind from community_threads
         where type = 'CommunityMarker' AND id = ? union all

        select id, title, content, user_id, created_at, 0 as community_id, thread_id, 'CommunityReply' as parent_thread_type, 'CommunityReply' AS kind from community_replies
        where id = ?
        order by created_at desc
      SQL
      return [sql, id, id, id, id]
    else
      sql =<<-SQL
        select id ,title, content, user_id, created_at, community_id, 0 as thread_id, 'CommunityThread' as parent_thread_type, 'CommunityTopic' AS kind from community_threads where type = 'CommunityTopic'
        union all

        select id ,title, content, user_id, created_at, community_id, 0 as thread_id, 'CommunityThread' as parent_thread_type, 'CommunityEvent' AS kind  from community_threads where type = 'CommunityEvent'
        union all

        select id, title, content, user_id, created_at, community_id, 0 as thread_id, 'CommunityThread' as parent_thread_type, 'CommunityMarker' AS kind from community_threads where type = 'CommunityMarker'
        union all

        select id, title, content, user_id, created_at, 0 as community_id, thread_id,'CommunityReply' as parent_thread_type, 'CommunityReply' AS kind from community_replies
        order by created_at desc
      SQL
      return [sql]
    end
  end

  def self.all_community_topics_query(community_id)
    community = Community.find(community_id)
    conditions = ['community_id = ?', community.id]

    community_event = CommunityEvent.find(:all, :conditions => conditions)
    community_topic = CommunityTopic.find(:all, :conditions => conditions)
    community_marker = CommunityMarker.find(:all, :conditions => conditions)

    event_id = []
    topic_id = []
    marker_id = []
    community_event.each{|event| event_id << event.id}
    community_topic.each{|topic| topic_id << topic.id}
    community_marker.each{|marker| marker_id << marker.id}

    sql =<<-SQL
    select id ,title, content, user_id, created_at, community_id, 0 as thread_id,
           'CommunityThread' as parent_thread_type, 'CommunityEvent' as thread_type
    from community_events where id in (?) union all
    select id ,title, content, user_id, created_at, community_id, 0 as thread_id,
           'CommunityThread' as parent_thread_type, 'CommunityTopic' as thread_type
    from community_topics where id in (?) union all
    select id ,title, content, user_id, created_at, community_id, 0 as thread_id,
           'CommunityThread' as parent_thread_type, 'CommunityMarker' as thread_type
    from community_markers where id in (?) union all
    select id, title, content, user_id, created_at, 0 as community_id, thread_id,
           'CommunityReply' as parent_thread_type, thread_type from community_replies
    where (thread_type = 'CommunityEvent' and thread_id in (?)) or
          (thread_type = 'CommunityTopic' and thread_id in (?)) or
          (thread_type = 'CommunityMarker' and thread_id in (?))
    order by created_at desc
    SQL
    return [sql, event_id, topic_id, marker_id, event_id, topic_id, marker_id]
  end

  # トピックを表すアイコンのパスを返す
  def icon_path
    "community/comm_topic.gif"
  end

  # コミュニティをトピック数でソートする場合にトピック数をカウントするSQLを返す
  # order by句のサブクエリとして使用する
  def self.sql_for_sort_by_count
    %Q(SELECT count(*) FROM community_threads WHERE communities.id = community_threads.community_id AND community_threads.type = 'CommunityTopic')
  end
end
