# あしあとをカウントするためのモジュール
#
# include後、tracking_counterメソッドを使用
module Mars::Track::Trackable
  def self.included(base)
    base.extend(ClassMethods)
  end

  module ClassMethods
    # あしあととしてカウントするアクションを定義
    #
    # ==== 引数
    #
    # * page_type_sym - ページタイプを表すシンボル
    # * actions - アクションの配列
    def tracking_counter(page_type_sym, actions)
      class_eval <<-EOV
        include Mars::Track::Trackable::InstanceMethods

        @@page_type = Track.page_type(page_type_sym)

        cattr_accessor :page_type

        after_filter :save_track, :only => actions
      EOV
    end
  end

  module InstanceMethods

    private

    # あしあとの記録用に呼ばれるメソッド
    def save_track
      if current_user && displayed_user && (current_user.id != displayed_user.id)
        Track.create(:user_id => displayed_user.id,
                     :visitor_id => current_user.id,
                     :page_type => page_type)
      end
    end
  end
end
