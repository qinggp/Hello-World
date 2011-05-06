module Mars::Blog::ControllerExtension
  module Friends
    def self.included(base)
      base.send(:include, InstanceMethods)
    end
  end

  module InstanceMethods
    # トモダチの最新ブログを新着情報としてトップページに表示するかどうかを切り替える
    #
    # ==== 引数
    #
    # * params[:id] - トモダチのID
    def change_new_blog_entry_displayed
      friend = User.find(params[:id])
      current_user.change_new_blog_entry_displayed(friend)

      redirect_to maintenance_friends_path
    end
  end
end
