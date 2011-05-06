require_dependency "#{File.expand_path(File.dirname(__FILE__))}/lib/mars/track/controller_extensions"

class TrackExtension < Mars::Extension

  def activate
    ui.my_menus.add :track
    ui.preferences[:notice].add :notification_track_count

    UsersController.send(:include, Mars::Track::ControllerExtension::Users)
    FriendsController.send(:include, Mars::Track::ControllerExtension::Friends)

    ui.mobile_main_menus.add :track, :type => :part, :extension => self
    Preference.send(:include, Mars::Track::ModelExtension::Preference)
    User.send(:include, Mars::Track::ModelExtension::User)
  end

  def after_activate
    if TrackExtension.instance.extension_enabled?(:blog)
      BlogEntriesController.send(:include, Mars::Track::ControllerExtension::BlogEntries)
    end

    if TrackExtension.instance.extension_enabled?(:community)
      CommunitiesController.send(:include, Mars::Track::ControllerExtension::Communities)
    end

    if TrackExtension.instance.extension_enabled?(:schedule)
      SchedulesController.send(:include, Mars::Track::ControllerExtension::Schedules)
    end
  end

  def deactivate
    ui.my_menus.remove :track
    ui.preferences[:notice].remove :notification_track_count

    ui.mobile_main_menus.remove :track
  end
end
