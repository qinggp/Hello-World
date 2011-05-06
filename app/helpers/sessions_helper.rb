# -*- coding: utf-8 -*-
module SessionsHelper
  # 簡単ログインを表示するか？（携帯用）
  def easy_login?
    return true if request.mobile.is_a?(Jpmobile::Mobile::Docomo)
    return false if request.mobile.ident.blank?
    return true if User.find_by_mobile_ident(request.mobile.ident)
    return false
  end

  # 携帯用ログインオプション
  #
  # ==== 備考
  # 
  # Docomoの時だけ個体識別番号をログイン時に送るようにする。
  def login_options_mobile
    if request.mobile.is_a?(Jpmobile::Mobile::Docomo)
      return {:utn => ""}
    else
      return {}
    end
  end
end
