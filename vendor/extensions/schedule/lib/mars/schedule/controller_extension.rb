module Mars::Schedule::ControllerExtension
  module Sessions
    def self.included(base)
      base.class_eval {
        before_filter :set_calendar_params, :except => %w(show_calendar)
      }
      base.send(:include, Mars::CalendarViewable)
      base.send(:include, Mars::Schedule::ControllerExtension::Sessions::InstanceMethods)
    end

    module InstanceMethods
      private

      # カレンダー表示に必要なパラメータ設定
      # 非ログインユーザに見せるので、以下の情報が表示される
      # 外部公開コミュニティで、かつイベントがカレンダー公開になっている
      def set_calendar_params
        @schedules_date = []
        if ScheduleExtension.instance.extension_enabled?(:community)
          CommunityEvent.on_calender_for_outer.
            by_event_date_on_month(@calendar_year, @calendar_month).each do |event|
            @schedules_date << event.event_date
          end
        end
        @schedules_date.uniq!
      end
    end
  end

  module Users
    def self.included(base)
      base.class_eval {
        before_filter :set_calendar_params,
        :only => %w(show new_friend_application edit_friend_description my_home
                                  update_friend_description)
      }
      base.send(:include, Mars::CalendarViewable)
      base.send(:include, Mars::Schedule::ControllerExtension::Users::InstanceMethods)
    end

    module InstanceMethods
      private

      # カレンダー表示に必要なパラメータ設定
      def set_calendar_params
        # 表示するスケジュールをもつユーザ
        @schedule_user = displayed_user || User.find_by_id(params[:id]) || current_user

        # 表示するスケジュールのユーザの公開スケジュールを取得
        public_user_schedules = @schedule_user.schedules.public_is(true)

        # ログインユーザと、表示するスケジュールのユーザが異なる場合、非公開スケジュールは表示しない
        if @schedule_user.same_user?(current_user)
          private_user_schedules = @schedule_user.schedules.public_is(false)
        else
          private_user_schedules = []
        end

        # ログインユーザと、表示するスケジュールのユーザが同じ場合は、誕生日の公開範囲が、「トモダチまで」以上
        # そうでない場合は、表示する誕生日の公開範囲が「公開」のみを表示
        # 誕生日は、判定が他と異なるので、別変数に対象となるトモダチを格納
        if @schedule_user.same_user?(current_user)
          @friends_for_schedule = User.by_birthday_visible_for_user(@schedule_user, false)
        else
          @friends_for_schedule = User.by_birthday_visible_for_user(@schedule_user, true)
        end
        @friends_for_schedule = @friends_for_schedule.by_birthday_on_month(@calendar_year, @calendar_month)

        @schedules_date = []
        @schedules_date << public_user_schedules.map{|s| s.due_date}
        @schedules_date << private_user_schedules.map{|s| s.due_date}
        if ScheduleExtension.instance.extension_enabled?(:community)
          events = @schedule_user.community_events.find(:all, :include => :community,
                                                        :conditions => ["communities.visibility NOT IN (?)",
                                                                        [Community::VISIBILITIES[:secret],
                                                                         Community::VISIBILITIES[:private]]])
          @schedules_date << events.map{ |e| e.event_date }
        end
        @schedules_date.flatten!
        @schedules_date.uniq!
      end
    end
  end
end
