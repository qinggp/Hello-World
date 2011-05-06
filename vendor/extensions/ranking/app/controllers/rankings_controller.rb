# ランキング管理
class RankingsController < ApplicationController

  before_filter :check_ranking_display_flg

  access_control do
    allow logged_in
  end

  # ランキングを表示する
  def index
    @limit = 10  # 上位何番まで表示するかを表す

    if params[:type] == "total"
      prepare_for_total_ranking
    else
      prepare_for_latest_ranking
    end
  end

  # コントローラ単位でのコンテンツホームのパスを返す
  def contents_home_path
    rankings_path
  end

  private

  # 総合ランキングを表示するために、各種ランキング情報の取得
  def prepare_for_total_ranking
    if RankingExtension.instance.extension_enabled?(:track)
      @access_ranking = Track.access_ranking(@limit)
    end

    if RankingExtension.instance.extension_enabled?(:community)
      @member_count_ranking = Community.member_count_ranking(@limit)
    end
    if RankingExtension.instance.extension_enabled?(:blog)
      @blog_entry_ranking = User.blog_entry_ranking(@limit)
    end
    @friend_count_ranking = User.friend_count_ranking(@limit)

    @invitation_count_ranking = User.invitation_count_ranking(@limit)
  end

  # 最新ランキングを表示するために、各種ランキング情報の取得
  def prepare_for_latest_ranking
    if RankingExtension.instance.extension_enabled?(:track)
      @latest_accesses_ranking = Track.access_ranking(@limit, period(1, 1))
    end

    if RankingExtension.instance.extension_enabled?(:community)
      @latest_community_comments_ranking = Community.comments_post_ranking(@limit, period(1, 1))
      @latest_member_count_ranking = Community.member_count_ranking(@limit, period(3, 0))
    end

    if RankingExtension.instance.extension_enabled?(:blog)
      @latest_popular_blog_ranking = BlogEntry.popular_ranking(@limit, period(3, 0))
    end

    @latest_friend_count_ranking = User.friend_count_ranking(@limit, period(3, 0))
  end

  # 何日前から何日前までのデータを取得するときのオプションを構築する
  def period(beginning_days_ago, end_days_ago)
    {:start_date => Time.now.advance(:days => -beginning_days_ago).beginning_of_day,
     :end_date => Time.now.advance(:days => -end_days_ago).end_of_day}
  end

  # SNS設定で、ランキング表示がオフになっていればトップページへリダイレクトさせる
  def check_ranking_display_flg
    redirect_to root_url unless SnsConfig.ranking_display_flg
  end
end
