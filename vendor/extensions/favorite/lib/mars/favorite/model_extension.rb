module Mars::Favorite::ModelExtension
  module User
    def self.included(base)
      base.class_eval do
        has_many :favorites, :dependent => :destroy
      end
    end
  end
end
