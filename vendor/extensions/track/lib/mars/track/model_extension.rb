module Mars::Track::ModelExtension
  module Preference
    def self.included(base)
      base.class_eval {
        has_one :track_preference, :autosave => true, :dependent => :destroy

        accepts_nested_attributes_for :track_preference

        validates_associated :track_preference

        # あしあと設定の関連追加
        self.add_preference_associations :track_preference
      }
    end
  end

  module User
    def self.included(base)
      base.class_eval do
        has_many :tracks, :dependent => :destroy
      end
    end
  end
end
