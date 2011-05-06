# 書き込み管理機能
class Admin::ContentsController < Admin::ApplicationController

# 書き込み管理機能の検索ジャンル
  GENRE = []
  if Mars::Extension.instance.extension_enabled?(:blog)
    GENRE << ["ブログ","blog_entries"]
    GENRE << ["ブログコメント", "blog_comments" ]
  end

  if Mars::Extension.instance.extension_enabled?(:community)
    GENRE << ["コミュニティ", "communities" ]
    GENRE << ["トピックス", "topics"]
    GENRE << ["イベント", "events"]
  end
  GENRE << ["プロフィール", "face_photo" ]
  GENRE.freeze

# 書き込み管理機能の検索種類
  TYPE = [
    ["書き込み", "write" ],
    ["ファイル", "file"]
  ]


  # 書き込み管理トップ画面の表示
  def search_top
    if params[:search] && params[:type] && params[:genre]
      redirect_controller_name =
        case params[:genre]
        when "blog_entries"
          'admin/blog_entries'
        when "blog_comments"
          params[:type] = "write"
          'admin/blog_entries'
        when "communities", "topics", "events"
          'admin/communities'
        when "face_photo"
          params[:type] = "file"
          'admin/users'
        end

      redirect_path = {
       :controller =>  redirect_controller_name,
       :action => "wrote_administration_#{params[:genre]}",
       :type => params[:type],
      }
      redirect_path.merge!(:search_id => params[:search_id]) if params[:search_id] != ''
      redirect_path.merge!(:secret_view => params[:secret_view]) if params[:secret_view]


      return redirect_to redirect_path
    end
  end



end
