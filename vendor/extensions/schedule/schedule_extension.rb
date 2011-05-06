require_dependency "#{File.expand_path(File.dirname(__FILE__))}/lib/mars/schedule/model_extension"

class ScheduleExtension < Mars::Extension

  def activate
    ui.my_menus.add :my_schedule
    ui.friend_menus.add :friend_schedule, :type => :part, :extension => self
    ui.preferences[:visibility].add :schedule_visibility
    ui.navigations.add :schedule_calendar_navigation, :extension => self
    ui.portal_navigations.add :schedule_calendar_navigation, :extension => self

    ui.mobile_profile_menus.add :friend_schedule_link, :type => :part, :extension => self
    ui.mobile_main_menus.add :my_schedule, :type => :part, :extension => self

    User.send(:include, Mars::Schedule::ModelExtension::User)
    UsersController.send(:include, Mars::Schedule::ControllerExtension::Users)
    SessionsController.send(:include, Mars::Schedule::ControllerExtension::Sessions)
    Preference.send(:include, Mars::Schedule::ModelExtension::Preference)
  end

  def deactivate
    ui.my_menus.remove :my_schedule
    ui.friend_menus.remove :friend_schedule
    ui.preferences[:visibility].remove :schedule_visibility
    ui.navigations.remove :schedule_calendar_navigation
    ui.portal_navigations.remove :schedule_calendar_navigation

    ui.mobile_main_menus.remove :my_schedule
    ui.mobile_profile_menus.remove :friend_schedule_link
  end
end
