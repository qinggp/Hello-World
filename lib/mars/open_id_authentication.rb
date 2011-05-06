# 自動ログインを行うために、認証後のリダイレクトするURLにrememberパラメータを追加
module Mars::OpenIdAuthentication
  def self.included(recipient)
  recipient.module_eval {
      private
      def open_id_redirect_url(open_id_request, return_to = nil, method = nil)
        open_id_request.return_to_args['_method'] = (method || request.method).to_s
        open_id_request.return_to_args['open_id_complete'] = '1'
        open_id_request.return_to_args['remember_me'] = '1' if params[:remember_me] == "1"  # 追加
        open_id_request.redirect_url(root_url, return_to || requested_url)
      end
    }
  end
end
