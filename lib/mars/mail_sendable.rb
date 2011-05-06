# メール送信用ユーティリティメソッド定義
#
# ActiveMailer::Baseを継承したモデルにincludeしてください。
module Mars::MailSendable
  def self.included(klass)
    klass.send(:include, InstanceMethods)
  end

  module InstanceMethods
    # Mars用Subject設定
    def setup_subject!(text)
      subject base64("【#{SnsConfig.title}】#{text}")
    end

    # ヘッダ情報設定
    def setup_send_info!(options)
      user = options[:user]
      from SnsConfig.admin_mail_address
      recipients options[:mobile] ? user.mobile_email : user.login
      reply_to  options[:mobile] ? user.mobile_email : user.login
      sent_on  Time.now
    end
  end
end
