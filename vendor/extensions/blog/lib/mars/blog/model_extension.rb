module Mars::Blog::ModelExtension
  module Preference
    def self.included(base)
      base.class_eval {
        has_one :blog_preference, :autosave => true, :dependent => :destroy

        accepts_nested_attributes_for :blog_preference

        validates_associated :blog_preference

        # ユーザブログ設定の関連追加
        self.add_preference_associations :blog_preference
      }
    end
  end

  module User
    def self.included(base)
      base.class_eval {
        has_many :blog_entries, :dependent => :destroy
        has_many :blog_comments, :dependent => :destroy
        has_many :blog_categories, :dependent => :destroy
      }
      base.send(:include, InstanceMethods)
    end

    module InstanceMethods
      # トモダチの最新ブログを表示できるかどうかを返す
      def new_blog_entry_displayed?(friend)
        Friendship.find(:first, :conditions => ["user_id = ? AND friend_id = ?", self.id, friend.id]).try(:new_blog_entry_displayed)
      end

      # トモダチの最新ブログを表示設定を切り替える
      def change_new_blog_entry_displayed(friend)
        friendship = Friendship.find(:first, :conditions => ["user_id = ? AND friend_id = ?", self.id, friend.id])
        friendship.update_attributes(:new_blog_entry_displayed => !friendship.new_blog_entry_displayed)
      end
    end
  end

  module SnsConfig
    def self.included(base)
      base.class_eval {
        enum_column :blog_default_open_range, :to_friends, :to_all, :to_outside
        validates_inclusion_of :blog_default_open_range, :in => ::SnsConfig::BLOG_DEFAULT_OPEN_RANGES.values
      }
    end
  end
end
