module Mars::Track::ControllerExtension
  module Users
    def self.included(base)
      base.class_eval {
        include Mars::Track::Trackable
        tracking_counter :profile, :show
      }
    end
  end

  module Friends
    def self.included(base)
      base.class_eval {
        include Mars::Track::Trackable
        tracking_counter :friend, :index
      }
    end
  end

  module BlogEntries
    def self.included(base)
      base.class_eval {
        include Mars::Track::Trackable
        tracking_counter :blog, %w(show index_for_user)
      }
    end
  end

  module Communities
    def self.included(base)
      base.class_eval {
        include Mars::Track::Trackable
        tracking_counter :community, :index
      }
    end
  end

  module Schedules
    def self.included(base)
      base.class_eval {
        include Mars::Track::Trackable
        tracking_counter :schedule, :show_calendar
      }
    end
  end
end

