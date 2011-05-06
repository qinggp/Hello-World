# メール受信用ユーティリティメソッド定義
#
# ActiveMailer::Baseを継承したモデルにincludeしてください。
#
# @@category_prefix を設定してください。
# 例 : ブログ @@category_prefix = "b"
# （設定する値は他のクラスと重複しないように気をつけてください）
module Mars::MailReceivable
  def self.included(klass)
    klass.send(:include, InstanceMethods)
    klass.extend ClassMethods
  end

  module InstanceMethods

    # EMailの検証を行う
    def valid_email?(email)
      private_token = extract_private_token_by_to(first_to_me(email))
      user = User.mobile_email_is(email.from.first.to_s.downcase).first

      return false if !user || user.private_token != private_token
      if email.sender
        user = User.mobile_email_is(email.sender.to_s.downcase).first
        return false if !user || user.private_token != private_token
      end
      return true
    end

    # ToアドレスからユーザIDを取り出す
    def extract_user_id_by_to(to)
      return $1 if to.match(/\A\w+-(\d+)/)
      return ""
    end

    # Toアドレスからユーザのprivate_tokenを取り出す
    def extract_private_token_by_to(to)
      return $1 if to.match(/\A#{Regexp.escape self.category_prefix}(\w+)/)
      return ""
    end

    # 受け取ったメール情報のSubjectをDBに保存できる形式にします
    def normalize_subject_for_db(email)
      subject = NKF.nkf("-w", email.subject)
    end

    # 受け取ったメール情報のBodyをDBに保存できる形式にします
    def normalize_body_for_db(email)
      body = ""
      if email.multipart?
        if mail = email.parts.detect{|m| m.main_type == 'text'}
          body = mail.body
        end
      else
        body = email.body
      end
      NKF.nkf("-w", body)
    end

    # emailのtoの中から、本システム宛の最初のアドレスを返す
    def first_to_me(email)
      to = email.to.detect { |address| address =~ /\A.+@(#{Regexp.escape CONFIG["mail"]["receive_domain"]})\z/ }
      return to.nil? ? "" : to
    end
  end

  module ClassMethods

    # 受信アドレス返却
    #
    # ==== 引数
    #
    # * user
    # * suffixes - アドレスローカル部のsuffixリスト
    #
    # ==== 戻り値
    #
    # 受信アドレス文字列
    def mars_receive_address(user, suffixes=[])
      local = [category_prefix + user.private_token, user.id, suffixes].flatten.join("-")
      domain = CONFIG["mail"]["receive_domain"]
      return local + "@" + domain
    end
  end
end
