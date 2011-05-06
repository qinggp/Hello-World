module Mars::SnsLinkage::ModelExtension
  module User
    def self.included(base)
      base.class_eval {
        has_many :sns_linkages, :dependent => :destroy
      }
    end
  end
end
