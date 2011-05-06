# SNS連携データWebAPI
class SnsLinkageApiController < ApplicationController
  layout false
  class SnsLinkageApiError < StandardError; end

  # SNS連携データ出力
  def show
    key, type = parse_query_string
    user = User.find_by_sns_link_key(key)
    raise SnsLinkageApiError, "not found user : key = #{key}" unless user
    send(type, user)
  rescue SnsLinkageApiError => ex
    logger.debug{ "DEBUG: #{ex.class} : #{ex.message}" }
    render :text => ""
  end

  private
  # 注目情報出力
  def notice(user)
    @items = []

    # トモダチ承認
    unless (count = Friendship.by_applied_to_user(user).size).zero?
      @items << item_plan(:title => "トモダチ依頼が#{count}件あります。")
    end

    # コミュニティ参加依頼
    if SnsLinkageExtension.instance.extension_enabled?(:community)
      count = user.communities.select{|c| c.admin?(user) }.
        map{|c| c.pending_community_users }.flatten.size
      unless count.zero?
        @items << item_plan(:title => "コミュニティ参加依頼が#{count}件あります。")
      end
    end
    
    # 新着メッセージ
    unless (count = Message.receiver_id_is(user.id).unread_is(true).size).zero?
      @items << item_plan(:title => "新着メッセージが#{count}件あります。")
    end
    render "rss.rxml", :content_type => "application/xml"
  end

  # 最新情報出力
  def news(user)
    @items = []

    # ブログ最新情報
    set_blog_news(user) if SnsLinkageExtension.instance.extension_enabled?(:blog)

    # コミュニティ最新情報
    set_community_news(user) if SnsLinkageExtension.instance.extension_enabled?(:community)

    render "rss.rxml", :content_type => "application/xml"
  end

  # サイトからのお知らせ
  def info(user)
    @items = []

    # 重要なのお知らせ
    infos =
      Information.
        by_viewable_for_user(user).
          display_type_is(Information::DISPLAY_TYPES[:important]).
            by_not_expire.find(:all, :order => Information.default_index_order)
    infos.each {|i| set_info(i, "重要なお知らせ") }

    # 重要なのお知らせ
    infos =
      Information.
        by_viewable_for_user(user).
          display_type_is(Information::DISPLAY_TYPES[:new]).
            by_not_expire.find(:all, :order => Information.default_index_order,
                               :limit => 5)
    infos.each {|i| set_info(i, "お知らせ") }

    render "rss.rxml", :content_type => "application/xml"
  end

  # ブログの新着データ設定
  def set_blog_news(user)
    entries = BlogEntry.by_new_blog_entry_displayed_for_user(user).
      by_visible_for_user(user, false).recents(10, 14.day.ago)
    entries.each do |e|
      @items << {:title => e.title, :link => blog_entry_url(e), :author => e.user.name,
        :pubDate => e.created_at, :category => "トモダチ最新ブログ"}
    end
    comments = BlogComment.recents_my_blog(user, nil, 10, 14.day.ago)
    comments.each do |c|
      @items << {:title => c.blog_entry.title, :link => blog_entry_url(c.blog_entry),
        :author => c.comment_user_name, :pubDate => c.created_at, :category => "最新マイブログコメント"}
    end
  end

  # コミュニティの新着データ設定
  def set_community_news(user)
    threads = Community.threads_order_by_post(user,
                                              :days_ago => 14,
                                              :limit => 10)
    threads.each do |t|
      @items << {:title => t.title, :link => t.polymorphic_url_on_community(@template),
        :author => t.author.name, :pubDate => t.created_at, :category => "コミュニティ最新書き込み"}
    end
  end

  # 重要なお知らせ設定
  def set_info(i, category)
    @items <<
      item_plan(:title => i.title,
                :link => (i.display_link_link? ? information_url(i) : ""),
                :pubDate => i.created_at, :category => category)
  end

  def parse_query_string
    if /[0-9a-z]*\.[a-z]*/ =~ request.query_string
      key, type = request.query_string.split(".")
      unless %w(notice news info).include?(type)
        raise SnsLinkageApiError, "invalid type : #{type}"
      end
      return [key, type]
    else
      raise SnsLinkageApiError, "invalid uri format"
    end
  end

  def item_plan(item)
    item[:link] ||= root_url
    item[:author] ||= SnsConfig.title
    item[:pubDate] ||= Time.now
    return item
  end
end
