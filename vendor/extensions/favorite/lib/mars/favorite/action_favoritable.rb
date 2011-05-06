# お気に入りに追加可能なアクションを定義
module Mars::Favorite::ActionFavoritable
  def self.included(base)
    base.extend(ClassMethods)
    base.class_eval do
      include InstanceMethods
    end
  end

  module ClassMethods

    # お気に入りに追加可能なアクションを定義
    #
    # ==== 引数
    # 
    # * category_name - カテゴリ名(:blog等）
    # * actions - 指定アクション
    # * options - オプション引数
    # * <tt>:if</tt> - if文(xx_filterと同じ仕様）
    # * <tt>:unless</tt> - unless文(xx_filterと同じ仕様）
    def favoritable_action(category_name, actions, options={})
      filter_keys = [:if, :unless]
      filter_args = {}
      filter_args.merge!(options.reject{|k, v| !filter_keys.include?(k) })
      filter_args[:only] = actions
      before_filter(filter_args) do |controller|
        logger.debug "DEBUG: favoritable_action!"
        controller.send(:set_favorite_action, category_name)
      end
    end
  end

  module InstanceMethods

    private

    # お気に入り追加可能アクション設定
    def set_favorite_action(category)
      return if current_user.blank?
      @favorite_category = category
      @favoritable_action = true
      @favorite = ::Favorite.user_id_is(current_user.id).find_by_url(request.request_uri)
    end
  end
end
