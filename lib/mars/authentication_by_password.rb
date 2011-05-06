# バリデーション項目修正のため、Authentication::ByPasswordを置き換え。
module Mars::AuthenticationByPassword
  # Stuff directives into including module
  def self.included(recipient)
    recipient.extend(Authentication::ByPassword::ModelClassMethods)
    recipient.class_eval do
      include Authentication::ByPassword::ModelInstanceMethods
      
      # Virtual attribute for the unencrypted password
      attr_accessor :password
      validates_presence_of     :password,                   :if => :password_required?
      validates_format_of(:password, :with => Mars::EN_ONE_BYTE_CHARS_AND_NUM_REGEX,
                          :message => Mars::BAD_EN_ONE_BYTE_CHARS_AND_NUM_MESSAGE,
                          :if => :password_required?)
      validates_length_of :password, :in => 6..12, :if => :password_required?
      validates_presence_of     :password_confirmation,      :if => :password_required?
      validates_confirmation_of :password,                   :if => :password_required?
      before_save :encrypt_password
    end
  end # #included directives
end
