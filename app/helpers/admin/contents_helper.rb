# 書き込み管理のヘルパ
module Admin::ContentsHelper
  # ジャンルのセレクトメニューの生成
  # ==== 引数
  # * options
  # * <tt>:param_name</tt> - パラメータの名前 --必須
  # * <tt>:checked_value</tt> - デフォルトの選択値
  def select_contents(select_data = [], options = { })
    param_name = options[:param_name]
    list = select_data.map do |array|
      [array[0], array[1]]
    end
    if params[param_name].blank?
      if options[:checked_value]
        checked_value = options[:checked_value]
      else
        checked_value = nil
      end
    else
      checked_value = params[param_name]
    end
    select_tag(param_name, options_for_select(list, checked_value))
  end

  # ユーザIDに対応したユーザ名を返す
  def username_extract(user_id)
    User.find(:first, :conditions =>['id = ?', user_id.to_i]).name
  end
end
