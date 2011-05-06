# == Schema Information
# Schema version: 20100227074439
#
# Table name: users
#
#  id                        :integer         not null, primary key
#  login                     :string(100)
#  name                      :string(100)     default("")
#  mobile_email              :string(100)
#  crypted_password          :string(40)
#  salt                      :string(40)
#  created_at                :datetime
#  updated_at                :datetime
#  remember_token            :string(40)
#  remember_token_expires_at :datetime
#  private_token             :string(10)
#  birthday                  :date
#  birthday_visibility       :integer
#  openid_url                :string(255)
#  admin                     :boolean
#  mobile_ident              :string(100)
#  last_real_name            :string(255)
#  first_real_name           :string(255)
#  real_name_visibility      :integer
#  now_prefecture_id         :integer
#  now_zipcode               :string(255)
#  now_city                  :string(255)
#  now_street                :text
#  now_address_visibility    :integer
#  face_photo_id             :integer
#  face_photo_type           :string(255)
#  gender                    :integer
#  home_prefecture_id        :integer
#  blood_type                :integer
#  phone_number              :string(255)
#  job_id                    :integer
#  job_visibility            :integer
#  affiliation               :string(255)
#  affiliation_visibility    :integer
#  message                   :text
#  detail                    :text
#  invitation_id             :integer
#  logged_in_at              :datetime
#  approval_state            :string(255)
#  friends_count             :integer         default(0)
#  sns_link_key              :string(255)
#

require "securerandom"

class User < ActiveRecord::Base
  include AASM
  include Authentication
  include Mars::AuthenticationByPassword
  include Authentication::ByCookieToken
  extend ActiveSupport::Memoizable

  acts_as_authorization_subject
  acts_as_authorization_object

  belongs_to :now_prefecture, :class_name => "Prefecture"
  belongs_to :home_prefecture, :class_name => "Prefecture"
  belongs_to :job
  belongs_to :face_photo, :polymorphic => true, :autosave => true
  belongs_to :invitation, :class_name => "User"
  has_one :preference, :dependent => :destroy
  has_many :friendships
  has_many :friends, :through => :friendships, :conditions => ["friendships.approved = ?", true], :order => "friendships.created_at DESC"
  has_many :roles, :through => :roles_users
  has_many :roles_users
  has_many :sent_messages, :class_name => "Message",
           :foreign_key => "sender_id", :dependent => :destroy
  has_many :received_messages, :class_name => "Message",
           :foreign_key => "receiver_id", :dependent => :destroy
  has_many :users_hobbies, :dependent => :destroy
  has_many :hobbies, :through => :users_hobbies, :uniq => true
  has_many :groups, :dependent => :destroy
  has_many :invites, :order => "created_at DESC", :dependent => :destroy
  has_many :forgot_passwords, :dependent => :destroy

  accepts_nested_attributes_for :users_hobbies

  after_create :save_default_preference
  after_create :activate_at_aftef_create

  # 承認状態
  aasm_column :approval_state
  aasm_initial_state :pending
  aasm_state :pending                            # 承認待ち
  aasm_state :pause                              # 一時停止
  aasm_state :active, :after_enter => :approve   # 承認済み
  aasm_event :activate do
    transitions :to => :active, :from => [:pending, :pause]
  end

  # 公開範囲
  VISIBILITIES = {
    :publiced    => 1, # 公開
    :friend_only => 2, # トモダチのみ
    :unpubliced  => 3, # 非公開
    :member_only => 4, # メンバーのみ
  }.freeze

  enum_column :gender, :male, :female
  enum_column :blood_type, :a, :b, :o, :ab

  named_scope :by_birthday_visible_for_user, lambda{|user, publiced|
    friend_ids = user.friends.map(&:id)

    if publiced
      cond = ["users.birthday_visibility IN (?) AND users.id in (?)",
              [VISIBILITIES[:publiced]],
              friend_ids
             ]
    else
      cond = ["users.birthday_visibility IN (?) AND users.id in (?)",
              [VISIBILITIES[:publiced],
               VISIBILITIES[:member_only],
               VISIBILITIES[:friend_only]],
              friend_ids
             ]
    end
    {:conditions => cond}
  }

  named_scope :by_other_user, lambda{|user|
    {:conditions => ["id not in (?)", user.id]}
  }
  named_scope :by_hobby_id, lambda{|hobby_id|
    {:conditions => ["hobbies.id = ?", hobby_id], :joins => [:users_hobbies => :hobby]}
  }
  named_scope :by_activate, {:conditions => ["approval_state = ?", 'active']}
  named_scope :by_deactivate, {:conditions => ["approval_state != ?", 'active']}
  named_scope :by_pending, {:conditions => ["approval_state = ?", 'pending']}
  named_scope :by_birthday_on_month, lambda{|year, month|
    date = (year && month) ? Date.new(year, month) : Date.today.beginning_of_month

    unless date.leap?
      # 閏年の2/29生まれの人は、平年は3/1を誕生日として判定しているため、平年は2月29日生まれのひとを2月生まれとしてはいけない
      if date.month == 2
        # 2/29日生まれの人は除外
        conditions = ["extract(month from birthday) = ? AND extract(day from birthday) != ?", 2, 29]
      end
      if date.month == 3
        # 2/29生まれの人を含める
        conditions = ["extract(month from birthday) = ? OR (extract(month from birthday) = ? AND extract(day from birthday) = ?)", 3, 2, 29]
      end
    end
    {:conditions => conditions ? conditions : ["extract(month from birthday) = ?", date.month]}
  }

  @@default_index_order = 'users.logged_in_at DESC'
  @@presence_of_columns = [:last_real_name, :first_real_name, :login, :name,
                           :gender, :birthday, :now_zipcode, :now_prefecture_id, :now_city,
                           :now_street, :real_name_visibility, :birthday_visibility,
                           :now_address_visibility, :phone_number, :message, :detail
                          ].freeze

  validates_presence_of @@presence_of_columns
  validates_uniqueness_of :login
  validates_format_of :login, :with => Mars::EMAIL_REGEX, :message => Mars::BAD_EMAIL_MESSAGE
  validates_format_of :mobile_email, :with => Mars::EMAIL_REGEX, :message => Mars::BAD_EMAIL_MESSAGE, :allow_blank => true
  validates_format_of :now_zipcode, :with => /\A[0-9]{3}-[0-9]{4}\z/, :message => "は半角数字でxxx-xxxxの形式で入力してください。"
  validates_format_of :phone_number, :with => /\A[0-9]*-[0-9]*-[0-9]*\z/, :message => "は半角数字でxxx-xxx-xxxの形式で入力してください。"

  attr_accessible :login, :mobile_email, :name, :password, :password_confirmation,
                  :mobile_ident, :last_real_name, :first_real_name, :real_name_visibility,
                  :now_prefecture_id, :now_zipcode, :now_city, :now_street,
                  :now_address_visibility, :face_photo, :gender, :home_prefecture_id,
                  :blood_type, :phone_number, :hobby, :job_id, :job_visibility,
                  :affiliation, :affiliation_visibility, :message, :detail, :birthday_visibility,
                  :birthday, :job_id, :users_hobbies_attributes, :photo_attributes,
                  :change_first_real_name, :change_last_real_name, :change_name_reason,
                  :age_range_start, :age_range_end, :search_hobby_id, :haved_face_photo,
                  :current_password, :leave_reason, :mobile_email_account_domain,
                  :invitation, :approval_state, :ask_body, :error_message,
                  :errored_at, :error_page_url, :error_repeatability

  # 名前変更依頼に使用
  attr_accessor :change_first_real_name, :change_last_real_name, :change_name_reason
  # メンバ検索に使用
  attr_accessor :age_range_start, :age_range_end, :search_hobby_id, :haved_face_photo
  # パスワード変更、退会、承認に使用
  attr_accessor :current_password, :leave_reason, :reason
  # 問い合わせに使用
  attr_accessor :ask_body, :error_message, :errored_at, :error_page_url, :error_repeatability
  enum_column :error_repeatability, {:yes => "yes", :no => "no", :unclear => "unclear"}

  cattr_reader :default_index_order, :presence_of_columns

  # Authenticates a user by their login name and unencrypted password.  Returns the user or nil.
  #
  # uff.  this is really an authorization, not authentication routine.
  # We really need a Dispatch Chain here or something.
  # This will also let us return a human error message.
  #
  def self.authenticate(login, password)
    return nil if login.blank? || password.blank?
    u = find_by_login(login.downcase) # need to get the salt
    u && u.authenticated?(password) ? u : nil
  end

  def login=(value)
    write_attribute :login, (value ? value.downcase : nil)
  end

  def mobile_email=(value)
    write_attribute :mobile_email, (value ? value.downcase : nil)
  end

  # 誕生日であるかどうかを判定するメソッド
  # 閏年の2月29日生まれの人は、平年は3/1を誕生日とする
  # 法律上では生まれた日の前日の深夜24時に加齢される、とあるため平年ではその前日が28日にあたり、
  # その翌日が誕生日、つまり3/1になるのが自然だと思われる。
  def birthday?(date = Date.today)
    if self.birthday.month == 2 && self.birthday.day == 29 && !date.leap?
      return date.month == 3 && date.day == 1
    end
    self.birthday.month == date.month && self.birthday.day == date.day
  end

  # 年齢を計算する
  def age(date = Date.today)
    (date.strftime("%Y%m%d").to_i - self.birthday.strftime("%Y%m%d").to_i) / 10000
  end

  # selfからdisplayed_userを見たときに、displayed_userのトモダチの誕生日を表示してよいトモダチのbirthday_visibilityの配列を返す
  def birthday_visibilities_through(displayed_user)
    if self.same_user?(displayed_user)
      [VISIBILITIES[:publiced],  VISIBILITIES[:member_only], VISIBILITIES[:friend_only]]
    else
      [VISIBILITIES[:publiced]]
    end
  end

  # トモダチか？
  def friend_user?(user)
    return false if user.nil?
    return !!friendship_by_user_id(user.id).try(:approved?)
  end

  # 対象のユーザとのトモダチ関係取得
  def friendship_by_user_id(user_id)
    Friendship.user_id_is(self.id).friend_id_is(user_id).first
  end

  # Viewに渡すセレクトボックスのオプション（公開範囲用）
  def self.select_options_for_visibilities(*keys)
    keys.map do |key|
      [I18n.t("user.visibility_label.#{key}"), VISIBILITIES[key]]
    end
  end

  # Viewに渡すセレクトボックスのオプション（ユーザー状態用）
  def self.select_options_for_approval_state(*keys)
    keys.map do |key|
      [I18n.t("user.approval_state_label.#{key}"), key.to_s]
    end
  end

  # NOTE: それぞれのフィールドの公開範囲名を取得するメソッド定義
  %w(real_name birthday now_address affiliation job).each do |field|
    define_method("#{field}_visibility_name") do
      return VISIBILITIES.invert[send("#{field}_visibility")]
    end
  end

  def search_category_name
    return SEARCH_CATEGORY[params[:select_item]]
  end

  # 中間テーブルのhobby_idをfindしてレコードを取り出す。
  #
  # ==== 備考
  #
  # 中間テーブルがDB登録されていない場合に使用する。
  # 例：確認画面
  def find_hobbies_in_through_table
    self.users_hobbies.map(&:hobby_id).compact.map do |id|
      Hobby.find_by_id(id)
    end.compact
  end

  # 顔写真生成
  def photo_attributes=(attrs={})
    self.face_photo_attributes = attrs[:face_photo_attributes] unless attrs[:face_photo_attributes].blank?
    self.prepared_face_photo_attributes = attrs[:prepared_face_photo_attributes] unless attrs[:prepared_face_photo_attributes].blank?
  end

  # 顔写真はアップロード済みか？
  def face_photo_uploaded?
    self.face_photo && !self.face_photo.new_record?
  end

  # 顔写真クラスか？
  def self.face_photo_class?(str)
    return [PreparedFacePhoto, FacePhoto].map(&:to_s).include?(str.to_s)
  end

  # セーブ前処理
  def before_save
    make_private_token
    face_photo_destroy_for_before_save
    self.logged_in_at = Time.now if self.logged_in_at.nil?
  end

  # 名前変更用のvalid?メソッド
  def valid_for_request_new_name?
    valid?
    self.errors.add_on_blank %w(change_last_real_name change_first_real_name)
    return errors.empty?
  end

  # ID、パスワード変更用のvalid?メソッド
  def valid_for_edit_id_password?
    valid?
    self.errors.add_on_blank %w(current_password)
    unless self.authenticated?(current_password)
      self.errors.add(:current_password, "は入力したパスワードが一致しません。")
    end
    return errors.empty?
  end

  # 退会時のvalid?メソッド
  def valid_for_leave?
    valid?
    self.errors.add_on_blank %w(current_password leave_reason)
    unless self.authenticated?(current_password)
      self.errors.add(:current_password, "は入力したパスワードが一致しません。")
    end
    return errors.empty?
  end

  # 携帯メールアドレスのvalid?メソッド
  def valid_for_mobile_email?
    valid?
    self.errors.add_on_blank %w(mobile_email)
    valid_for_edit_id_password?
  end

  # お問い合わせ時のvalid?メソッド
  def valid_for_ask?
    self.errors.clear
    self.errors.add_on_blank %w(login first_real_name last_real_name ask_body)
    self.errors.add(:login, Mars::BAD_EMAIL_MESSAGE) unless self.login.to_s =~ Mars::EMAIL_REGEX
    return errors.empty?
  end

  # 指定したプロフィール項目を見られるユーザか？
  def visible_profile?(current_user, field_name)
    visibility = self.send(field_name.to_s + "_visibility")
    case visibility
    when VISIBILITIES[:publiced]
      return true
    when VISIBILITIES[:member_only]
      return false if current_user.nil?
      return true
    when VISIBILITIES[:friend_only]
      return false if current_user.nil?
      return true if self.id == current_user.try(:id)
      return current_user.friend_user?(self)
    when VISIBILITIES[:unpubliced]
      return false
    end
  end

  # 本名が修正されているか？
  def valid_real_name_not_changed?
    message = "は編集しないでください。"
    if self.changes.keys.include?("last_real_name")
      self.errors.add(:last_real_name, message)
      return false
    end
    if self.changes.keys.include?("first_real_name")
      self.errors.add(:first_real_name, message)
      return false
    end
    return true
  end

  # 同じユーザ？
  def same_user?(current_user)
    self.id == current_user.try(:id)
  end

  # 顔写真の子オブジェクトを削除
  def face_photo_destroy
    return if self.face_photo.nil?
    if self.face_photo.prepared?
      self.face_photo = nil
    else
      self.face_photo.destroy
    end
  end

  # メンバ検索オプション返却
  #
  # ==== 引数
  #
  # * search_params - Viewから渡ってきたパラメータ
  def self.search_member_options(search_params)
    u = User.new(search_params)
    res = {}
    %w(gender blood_type now_prefecture_id home_prefecture_id).each do |name|
      if !u.send(name).blank? && u.send(name) != 0
        res["#{name}_is".to_sym] = u.send(name)
      end
    end
    if !u.first_real_name.blank? || !u.last_real_name.blank?
      res[:first_real_name_is] = u.first_real_name.to_s
      res[:last_real_name_is] = u.last_real_name.to_s
      res[:real_name_visibility_equals] = [VISIBILITIES[:publiced], VISIBILITIES[:member_only]]
    end
    unless u.message.blank?
      res[:message_like] = u.message
      res[:detail_like] = u.message
    end
    res[:face_photo_id_not_null] = true unless u.haved_face_photo.blank?
    res[:name_like] = u.name unless u.name.blank?
    res[:now_city_like] = u.now_city unless u.now_city.blank?
    res[:by_hobby_id] = u.search_hobby_id unless u.search_hobby_id.blank?
    return res.merge(self.search_member_birthday_options(u))
  end

  # ログイン時間保存
  def update_logged_in_at!
    self.logged_in_at = Time.now
    self.save!
  end

  # 最終ログイン時間（現在の時刻からの差分）
  def logged_in_at_by_diff
    diff = Time.now - logged_in_at
        minutes = (diff / 60).ceil;
        hour = (diff / (60*60)).ceil;
        date = (diff / (60*60*24)).ceil;

    case
        when minutes <= 60
      %w(3 5 10 15 45 60).inject("") do |res, m|
        if minutes <= m.to_i
          break "#{m}分以内"
        end
      end
        when hour <= 24
      "#{hour}時間以内"
        when date <= 6
      "#{date}日以内";
        else
      "1週間以上";
    end
  end

  # 携帯メールアドレスの[アカウント名、ドメイン名]による設定
  def mobile_email_account_domain=(values={})
    if !values["domain"].blank? && !values["account"].blank?
      self.mobile_email = "#{values[:account]}@#{values[:domain]}"
    else
      self.mobile_email = ""
    end
  end

  # 携帯メールアドレスアカウント名
  def mobile_email_account
    return "" unless self.mobile_email
    self.mobile_email.split("@").first
  end

  # 携帯メールアドレスドメイン名
  def mobile_email_domain
    return "" unless self.mobile_email
    self.mobile_email.split("@").last
  end

  # 対象ユーザをトモダチにする
  #
  # ==== 引数
  #
  # * target_user - 対象ユーザ
  def friend!(target_user)
    [self, target_user].inject(target_user) do |target, user|
      if friendship = user.friendship_by_user_id(target.id)
        friendship.approved = true
        friendship.save!
      else
        user.friendships.build(:friend => target, :approved => true).save!
      end
      # NOTE: トモダチ数が変動するため再ロード
      user.reload
    end
  end

  # トモダチから外す
  def break_off!(friend)
    friendship_by_user_id(friend.id).try(:destroy)
    friend.friendship_by_user_id(self.id).try(:destroy)
    # NOTE: トモダチ数が変動するため再ロード
    friend.reload
    self.reload
  end

  # 招待者かどうか
  def invitation?(user)
    self.invitation_id == user.id
  end

  # トモダチになったばかりか？
  def hot_friend?(user)
    (Date.today - self.friendship_by_user_id(user.id).created_at.to_date).to_i <= 1
  end

  # トモダチとの関係の深さを表示する
  def display_friend_relation(friend)
    friendship = friendship_by_user_id(friend.id)
    return "" if !friendship.relation || friendship.relation == Friendship::RELATIONS[:nothing]
    relation_label_name = Friendship.human_attribute_name("relation")
    relation_name = I18n.t("friendship.relation_label.#{friendship.relation_name}")
    "[#{relation_label_name}：#{relation_name}]"
  end

  # トモダチとの接触の頻度を表示する
  def display_friend_contact_frequency(friend)
    friendship = friendship_by_user_id(friend.id)
    return "" if !friendship.contact_frequency || friendship.contact_frequency == Friendship::CONTACT_FREQUENCIES[:nothing]
    contact_frequency_label_name = Friendship.human_attribute_name("contact_frequency")
    contact_frequency_name = I18n.t("friendship.contact_frequency_label.#{friendship.contact_frequency_name}")
    "[#{contact_frequency_label_name}：#{contact_frequency_name}]"
  end

  # 本名取得
  def full_real_name
    "#{self.last_real_name} #{self.first_real_name}"
  end

  # ニックネームと本名取得
  def name_and_full_real_name
    "#{self.name}(#{self.full_real_name})"
  end

  # 名前を敬称付きで表示
  def name_with_suffix
    I18n.t("name_suffix", :value => self.name)
  end

  # 敬称付きで本名取得
  def full_real_name_with_suffix
    I18n.t("#{self.last_real_name} #{self.first_real_name}", :value => self.name)
  end

  # 承認（承認メール送信）
  def activate_with_notification!(approver)
    activate!
    UserApprovalNotifier.deliver_approve_notification(self)
    UserApprovalNotifier.deliver_approve_notification_to_approver(approver, self)
  end

  # 対象ユーザとのサイト内の関係性
  #
  # ==== 備考
  # memoize で計算結果をキャッシュしている
  def relationship_to_user(target)
    return [] if self.same_user?(target)
    return [self, target] if friend_user?(target)
    common_friends = self.friends.map(&:id) & target.friends.map(&:id)
    return [] if common_friends.empty?
    return [self, User.find(common_friends.choice), target]
  end
  memoize :relationship_to_user

  # 招待したトモダチ数
  def invite_friends_count
    self.friends.invitation_id_is(self.id).size
  end

  # 削除前処理
  def before_destroy
    User.by_activate.update_all("invitation_id = null", :invitation_id => self.id)
    self.friends.map{|friend| self.break_off!(friend)}
    face_photo_destroy
  end

  # 削除後処理
  # NOTE: before_destroyでユーザ削除前処理を行うとき、roleが消えてしまうと必要な処理が行えなくなることがあるため、最後に全てのroleを削除する
  def after_destroy
    self.has_no_roles!
  end

  # プロフィールページを表示してよいかどうか
  def profile_displayable?(user)
    return true if (self.preference.try(:profile_restraint_type_public?) || user)
    return false
  end

  private

  # 承認済みのトモダチを表示
  def friends_with_activate
    return self.friends_without_activate.approval_state_is('active')
  end
  alias_method_chain :friends, :activate

  # 顔写真の子オブジェクトを削除
  def face_photo_destroy_for_before_save
    if self.face_photo && self.face_photo._delete
      face_photo_destroy
    end
  end

  # ユーザ毎のプライベートなキーを設定する
  def make_private_token
    self.private_token = SecureRandom.hex[0..9] if new_record?
  end

  # 顔写真生成
  #
  # ==== 引数
  #
  # * attrs - フォーム値
  def face_photo_attributes=(attrs={})
    return if attrs.blank?
    if self.face_photo && !self.face_photo.prepared?
      self.face_photo.attributes = attrs
    else
      self.face_photo = FacePhoto.new(attrs)
    end
  end

  # デフォルト顔写真生成
  #
  # ==== 引数
  #
  # * attrs - フォーム値
  def prepared_face_photo_attributes=(attrs={})
    if !attrs[:id].blank? && self.face_photo.nil?
      self.face_photo = PreparedFacePhoto.find_by_id(attrs[:id])
    elsif !attrs[:_delete].blank?
      self.face_photo._delete = attrs[:_delete]
    end
  end

  # メンバ検索の誕生日部分作成
  def self.search_member_birthday_options(user)
    res = {}
    unless user.age_range_start.blank?
      if user.age_range_end.blank?
        res[:birthday_gt] = (user.age_range_start.to_i + 1).years.ago.to_date
      else
        res[:birthday_lte] = user.age_range_start.to_i.years.ago.to_date
        res[:birthday_gt] = (user.age_range_end.to_i + 1).years.ago.to_date
      end
      res[:birthday_visibility_equals] = [VISIBILITIES[:publiced], VISIBILITIES[:member_only]]
    end
    return res
  end

  # 空のユーザ設定を設定
  def save_default_preference
    self.preference ||= Preference.new(:user => self)
    self.preference.save!
  end

  # ユーザを承認する
  def approve
    if self.invitation
      self.invitation.friend!(self)
      self.friend!(self.invitation)
    end
    self.save!
  end

  # ユーザ作成後の承認処理
  def activate_at_aftef_create
    if SnsConfig.master_record.approval_type_no_approval? && self.pending?
      self.activate!
    end
  end
end
