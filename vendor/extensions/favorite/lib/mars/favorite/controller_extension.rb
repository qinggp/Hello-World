# 基盤、拡張コントローラを拡張
module Mars::Favorite::ControllerExtension

  # コントローラ群の拡張
  def self.extend_controllers
    UsersController.class_eval do
      include Mars::Favorite::ActionFavoritable
      favoritable_action "トモダチ", :show, :if => Proc.new{|controller|
        controller.send(:current_user).try(:id).to_s != controller.params[:id].to_s
      }
      favoritable_action "トモダチ", :edit_friend_description
      favoritable_action "トモダチ", :new_friend_application
    end

    FriendsController.class_eval do
      include Mars::Favorite::ActionFavoritable
      favoritable_action "トモダチ", :index
    end

    MessagesController.class_eval do
      include Mars::Favorite::ActionFavoritable
      favoritable_action "メッセージ", :new, :if => Proc.new{|controller| controller.params[:individually]}
      favoritable_action "メッセージ", :show
    end

    # （拡張）ブログ機能
    if FavoriteExtension.instance.extension_enabled?(:blog)
      BlogEntriesController.class_eval do
        include Mars::Favorite::ActionFavoritable
        favoritable_action "ブログ", :index_for_user
        favoritable_action "ブログ", :show
      end
    end

    # （拡張）コミュニティ機能
    if FavoriteExtension.instance.extension_enabled?(:community)
      CommunitiesController.class_eval do
        include Mars::Favorite::ActionFavoritable
        favoritable_action "コミュニティ", :show
        favoritable_action "コミュニティ", :show_members
        favoritable_action "コミュニティ", :index
        favoritable_action "コミュニティ", :new_message
      end
      CommunityTopicsController.class_eval do
        include Mars::Favorite::ActionFavoritable
        favoritable_action "コミュニティ", :show
      end
      CommunityMarkersController.class_eval do
        include Mars::Favorite::ActionFavoritable
        favoritable_action "コミュニティ", :show
        favoritable_action "コミュニティ", :map
      end
      CommunityEventsController.class_eval do
        include Mars::Favorite::ActionFavoritable
        favoritable_action "コミュニティ", :show
        favoritable_action "コミュニティ", :show_calendar
      end
      CommunityThreadsController.class_eval do
        include Mars::Favorite::ActionFavoritable
        favoritable_action "コミュニティ", :search
        favoritable_action "コミュニティ", :show_comment_tree
        favoritable_action "コミュニティ", :show_comment_tree_specified_thread
      end
      CommunityRepliesController.class_eval do
        include Mars::Favorite::ActionFavoritable
        favoritable_action "コミュニティ", :new
      end
    end

    # （拡張）スケジュール機能
    if FavoriteExtension.instance.extension_enabled?(:schedule)
      SchedulesController.class_eval do
        include Mars::Favorite::ActionFavoritable
        favoritable_action "スケジュール", :show_list
        favoritable_action "スケジュール", :show_calendar, :if => Proc.new{|controller|
          if controller.params[:user_id].blank?
            false
          else
            controller.send(:current_user).try(:id).to_s != controller.params[:user_id].to_s
          end
        }
      end
    end
  end
end
