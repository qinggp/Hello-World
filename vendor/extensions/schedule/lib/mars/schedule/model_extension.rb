module Mars::Schedule::ModelExtension
  module User
    def self.included(base)
      base.class_eval {
        has_many :schedules, :dependent => :destroy
      }
    end
  end

  module Preference
    def self.included(base)
      base.class_eval {
        has_one :schedule_preference, :autosave => true, :dependent => :destroy

        accepts_nested_attributes_for :schedule_preference

        validates_associated :schedule_preference

        # ユーザブログ設定の関連追加
        self.add_preference_associations :schedule_preference
      }
    end
  end
end
