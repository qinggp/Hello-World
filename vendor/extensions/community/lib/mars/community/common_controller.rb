# 拡張機能コミュニティのコントローラで共通して使用する機能をまとめたもの
module Mars::Community::CommonController
  def self.included(base)
    base.send(:include, InstanceMethods)
  end

  module InstanceMethods
    private

    # 返信の一覧表示オプション
    def paginate_options_for_reply
      return @paginate_options ||= {
        :page => (params[:page] ? sanitize_sql(params[:page]) : 1),
        :order => (params[:order] ? construct_sort_order : CommunityReply.default_index_order),
        :per_page => (params[:per_page] ? per_page_for_all(CommunityReply) : 20),
        :include => :author,
      }
    end

    # コミュニティ参加者や、イベント参加者一覧表示オプション
    def paginate_options_for_member
      return @paginate_options ||= {
        :order => (params[:order] ? construct_sort_order : User.default_index_order),
        :page => (params[:page] ? sanitize_sql(params[:page]) : 1),
        :per_page =>  (params[:per_page] ? per_page_for_all(User) : 30)}
    end

    # スレッドの一覧表示オプション
    def paginate_options_for_thread
      return @paginate_options ||= {
        :order => (params[:order] ? construct_sort_order : CommunityThread.default_index_order),
        :page => (params[:page] ? sanitize_sql(params[:page]) : 1),
        :per_page =>  (params[:per_page] ? per_page_for_all(CommunityThread) : 30)}
    end

    # ログインしていなくても閲覧できるかどうか
    # access_controlでanonymousのときの条件として使用する
    # ただし、コミュニティが特定できないようなときは常にtrue
    def anoymous_viewable?
      return @community.anoymous_viewable? if @community
      return true
    end

    # ログインしていればみれるかどうか
    # access_controlでlogged_inのときの条件として使用する
    # ただし、コミュニティが特定できないようなときは常にtrue
    def login_user_viewable?
      return @community.login_user_viewable? if @community
      return true
    end
  end
end
