# ユーザ管理（管理側）ヘルパ
module Admin::UsersHelper
  include Admin::ContentsHelper
  include ::UsersHelper

  #検索カテゴリ
  SEARCH_CATEGORY = {
    :e_mail => 0,
    :name => 1,
    :id => 2,
    :no_invitation => 3
  }.freeze

  # 確認画面のForm情報
  def form_params
    if @user
      case request.parameters[:action]
      when 'edit', 'update', 'confirm_before_update'
         {:url => confirm_before_update_admin_user_path(@user),
          :model_instance => @user, :multipart => true}
      when 'edit_passwd', 'update_passwd', 'confirm_before_update_passwd'
         {:url => confirm_before_update_passwd_admin_user_path(@user),
          :model_instance => @user}
      when 'delete', 'destroy', 'confirm_before_destroy'
         {:url => confirm_before_destroy_admin_user_path(@user),
          :model_instance => @reason}
      end
    end
  end

  # 登録・編集画面のForm情報
  def confirm_form_params
    case request.parameters[:action]
    when 'confirm_before_update'
        {:url => admin_user_path(:id => @user), :method => :put,
        :model_instance => @user}
    when 'confirm_before_update_passwd'
        {:url => update_passwd_admin_user_path(:id => @user), :method => :put,
        :model_instance => @user}
    when 'confirm_before_destroy'
        {:url => admin_user_path(:id => @user), :method => :delete,
        :model_instance => @reason}
    end
  end

  # NOTE: 管理者機能 検索カテゴリ名を取得するメソッド定義
  def select_options_for_admin_search_category(*keys)
    select_options = keys.map do |key|
      [I18n.t("user.search_category_label.#{key}"), SEARCH_CATEGORY[key]]
    end
    options_for_select(select_options, params[:search_category].to_i)
  end

  #プロフィール画像管理で画像表示
  def image_face_photo_list_view(user)
    link_to(theme_image_tag(show_unpublic_image_admin_user_path(:id => user.face_photo_id, :face_photo_id => user.face_photo_id, :image_type => 'thumb')),
        show_unpublic_image_admin_user_path(:id => user.face_photo_id, :face_photo_id => user.face_photo_id))
  end
end
