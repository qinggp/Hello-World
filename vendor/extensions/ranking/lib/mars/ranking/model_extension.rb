module Mars::Ranking::ModelExtension
  module Track
    def self.included(base)
      base.extend(ClassMethods)
    end

    module ClassMethods
      # ユーザへのあしあとを集計して、そのランキングを取得する
      def access_ranking(limit, period={})
        cond_s = []
        cond_v = []
        cond_s << "user_id IN (?) "
        cond_v << ::User.by_activate.find(:all, :select => :id).map(&:id)
        if period[:start_date] && period[:end_date]
          cond_s << "created_at between ? AND ?"
          cond_v << period[:start_date] << period[:end_date]
        end
        condition = cond_v.unshift(cond_s.join(" AND "))

        self.find(:all,
                  :select => "user_id, count(user_id) AS count",
                  :group => "user_id",
                  :order => "count DESC",
                  :limit => limit,
                  :conditions => condition)
      end
    end
  end

  module Community
    def self.included(base)
      base.extend(ClassMethods)
    end

    module ClassMethods
      # コミュニティへの投稿数（トピック、イベント、マーカー、及びそれらへの返信数）を集計して、
      # そのランキングを取得する
      def comments_post_ranking(limit, period = {})
        visibilities = [self::VISIBILITIES[:member], self::VISIBILITIES[:public]]

        # コミュニティのidがキーで、それへの投稿数を値とするハッシュ
        id_and_count = Hash.new(0)

        [CommunityEvent, CommunityTopic, CommunityMarker, CommunityReply].each do |klass|
          cond_s = ["communities.visibility IN (?)"]
          cond_v = [visibilities]
          if period[:start_date] && period[:end_date]
            cond_s << "#{klass.table_name}.created_at between ? AND ?"
            cond_v <<  period[:start_date] << period[:end_date]
          end
          condition = cond_v.unshift(cond_s.join(" AND "))

          klass.with_options(:group => "community_id", :joins => :community,
                             :conditions => condition) do |opt|
            opt.count.each do |id, count|
              id_and_count[id] += count
            end
          end
        end

        # 2重配列。コミュニティのidとそれへの投稿数を要素とする配列を格納する
        # 投稿数でソートされている
        sorted_id_and_count = id_and_count.sort_by{ |a| -a.second}.slice(0, limit)
        sorted_id_and_count.map do |a|
          self.find(a.first, :select => "*, #{a.second} AS count")
        end
      end

      # コミュニティの参加数を集計して、そのランキングを取得する
      def member_count_ranking(limit, period={})
        cond_s = []
        cond_v = []
        cond_s << "communities.visibility IN (?)"
        cond_v << [self::VISIBILITIES[:member], self::VISIBILITIES[:public]]
        cond_s << "communities.official IN (?)"
        cond_v << [self::OFFICIALS[:none], self::OFFICIALS[:normal]]
        if period[:start_date] && period[:end_date]
          cond_s << "community_memberships.created_at between ? AND ?"
          cond_v << period[:start_date] << period[:end_date]
        end
        condition = cond_v.unshift(cond_s.join(" AND "))

        communities = self.find(:all,
                                :select => "communities.id, communities.name, count(distinct community_memberships.user_id) AS count",
                                :joins => :community_memberships,
                                :group => "communities.id, communities.name",
                                :order  => "count DESC",
                                :limit => limit,
                                :conditions => condition)
      end
    end
  end

  module BlogEntry
    def self.included(base)
      base.extend(ClassMethods)
    end

    module ClassMethods
      # ブログへのアクセス数、及びコメント数を集計してランキングを取得する
      def popular_ranking(limit, period={})
        cond_s = []
        cond_v = []
        cond_s << "visibility IN (?)"
        cond_v << [BlogPreference::VISIBILITIES[:member_only],
                   BlogPreference::VISIBILITIES[:publiced]]
        if period[:start_date] && period[:end_date]
          cond_s << "created_at between ? AND ?"
          cond_v << period[:start_date] << period[:end_date]
        end
        user_ids = ::User.by_activate.find(:all, :select => :id).map(&:id)
        cond_s << "blog_entries.user_id IN (?)"
        cond_v << user_ids

        condition = cond_v.unshift(cond_s.join(" AND "))

         self.find(:all,
                  :select => "*, (access_count + blog_comments_count) AS count",
                  :order => "count DESC",
                  :limit => limit,
                  :conditions => condition)
      end
    end
  end

  module UserBlogEntry
    def self.included(base)
      base.extend(ClassMethods)
    end

    module ClassMethods
      # ユーザが書いたブログの記事の件数を集計して、そのランキングを取得する
      def blog_entry_ranking(limit)
        visibilities = [BlogPreference::VISIBILITIES[:member_only],
                        BlogPreference::VISIBILITIES[:publiced],
                        BlogPreference::VISIBILITIES[:friend_only]]

        ::User.find(:all,
                    :select => "users.id, users.name, users.face_photo_id, users.face_photo_type, count(blog_entries.id)",
                    :group => "users.id, users.name, users.face_photo_id, users.face_photo_type",
                    :joins => :blog_entries,
                    :order => "count DESC",
                    :limit => limit,
                    :conditions => ["blog_entries.visibility IN (?) AND users.approval_state = ?", visibilities, "active"])
      end
    end
  end

  module User
    def self.included(base)
      base.extend(ClassMethods)
    end

    module ClassMethods
      # トモダチの数を集計して、そのランキングを取得する
      def friend_count_ranking(limit, period={})
        cond_s = []
        cond_v = []
        cond_s << "users.approval_state = ?"
        cond_v << "active"
        if period[:start_date] && period[:end_date]
          cond_s << "friendships.created_at between ? AND ?"
          cond_v << period[:start_date] << period[:end_date]
        end
        condition = cond_v.unshift(cond_s.join(" AND "))

        users = self.find(:all,
                          :select => "users.id, users.name, users.face_photo_id, users.face_photo_type, count(distinct friendships.friend_id) AS count",
                          :joins => :friends,
                          :group => "users.id, users.name, users.face_photo_id, users.face_photo_type",
                          :order => "count DESC",
                          :limit => limit,
                          :conditions => condition)
      end

      # 招待した数を集計して、そのランキングを取得する
      def invitation_count_ranking(limit)
        invitaion_and_counts = self.count(:conditions => "invitation_id is not null",
                                          :group => "invitation_id",
                                          :limit => limit,
                                          :order => "count(invitation_id) DESC")
        invitation_ids = invitaion_and_counts.keys
        invitations = self.find(invitation_ids)

        invitations = invitation_ids.map do |id|
          invitations.detect {|invitation| invitation.id == id }
        end

        counts = invitaion_and_counts.values
        invitations.each_with_index do |invitation, index|
          invitation.instance_variable_set(:@count, counts[index])
          invitation.instance_eval{ def count; @count ;end }
        end
      end
    end
  end

  module SnsConfig
    def self.included(base)
      base.class_eval {
        enum_column :ranking_display_flg, :disable => false, :view => true
      }
    end
  end
end
