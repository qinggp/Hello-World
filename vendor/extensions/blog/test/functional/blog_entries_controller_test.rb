require File.dirname(__FILE__) + '/../test_helper'

# ブログ管理テスト
class BlogEntriesControllerTest < ActionController::TestCase

  def setup
    @update_record = BlogEntry.make
    @current_user = @update_record.user
    @current_user.has_role!(:blog_entry_author, @update_record)
    @current_user.preference.blog_preference = BlogPreference.make
    @current_user.save!
    login_as(@current_user)
  end

  # 新着ブログ表示（RSS2）
  def test_index_rss2
    hit_new = BlogEntry.make
    hit_old = BlogEntry.make(:created_at => 1.years.ago)

    get :index_feed, :format => "rss"

    not_hit_ids = assigns(:blog_entries).inject([hit_new, hit_old]){|res, i| res.shift if !res.empty? && res.first.id == i.id; res}
    assert_equal true, not_hit_ids.empty?
    assert_template('feed.rxml')
    assert_not_nil assigns(:xml_title)
    assert_not_nil assigns(:xml_link)
  end

  # 新着ブログ表示（RSS1.0）
  def test_index_rdf
    get :index_feed, :format => "rdf"

    assert_template('feed.rdf.builder')
    # puts @response.body
  end

  # 新着ブログ表示（Atom）
  def test_index_atom
    get :index_feed, :format => "atom"

    assert_template('feed.atom.builder')
    # puts @response.body
  end

  # 指定ユーザのブログ一覧画面表示
  def test_index_for_user
    logout

    get :index_for_user, :user_id => @current_user.id

    assert_response :success
    assert_not_nil assigns(:blog_entries)
  end

  # 指定ユーザのブログ一覧画面表示（外部RSS情報表示）
  def test_index_for_user_with_rss
    @current_user.preference.
      blog_preference.update_attribute(:rss_url,
        File.join(RAILS_ROOT, "test/fixtures/files/test.rss"))

    get :index_for_user, :user_id => @current_user.id

    assert_response :success
    assert_not_nil assigns(:blog_entries)
    assert_not_nil assigns(:blog_entries).any?{|e| e.imported_by_rss }
  end

  # カテゴリ指定のブログ一覧画面表示
  def test_index_for_user_category
    logout
    entry = BlogEntry.make

    get :index_for_user, :user_id => @current_user.id,
          :blog_category_id => entry.blog_category_id

    assert_response :success
    assert_not_nil assigns(:blog_entries)
  end

  # 年月指定のブログ一覧画面表示
  def test_index_for_user_year_moth
    logout
    entry = BlogEntry.make(:user_id => @current_user.id)
    date = Date.today

    get :index_for_user, :user_id => @current_user.id,
          :date => {:year => date.year, :month => date.month}

    assert_response :success
    entries = assigns(:blog_entries)
    assert_equal false, entries.empty?
    assert_not_nil entries.detect{|e| e.id == entry.id}
    assert_nil assigns(:calendar_day)
  end

  # 日付指定のブログ一覧画面表示
  def test_index_for_user_year_moth_day
    logout
    entry = BlogEntry.make(:user_id => @current_user.id)
    date = Date.today

    get :index_for_user, :user_id => @current_user.id,
          :date => {:year => date.year, :month => date.month, :day => date.day}

    assert_response :success
    entries = assigns(:blog_entries)
    assert_equal false, entries.empty?
    assert_not_nil entries.detect{|e| e.id == entry.id}
    assert_not_nil assigns(:calendar_day)
  end

  # メンバー個別のブログ表示（RSS2）
  def test_index_feed_for_user_rss2
    user = User.make
    hit_new = BlogEntry.make(:user_id => user.id)
    hit_old = BlogEntry.make(:user_id => user.id, :created_at => 1.years.ago)
    get :index_feed_for_user, :format => "rss", :user_id => user.id

    assert_equal hit_new.id, assigns(:blog_entries).first.id
    assert_equal 2, assigns(:blog_entries).count
    assert_template('feed.rxml')
    assert_not_nil assigns(:xml_title)
    assert_not_nil assigns(:xml_link)
  end

  # メンバー個別のブログ表示（RSS1.0）
  def test_index_feed_for_user_rdf
    get :index_feed, :format => "rdf"

    assert_template('feed.rdf.builder')
    # puts @response.body
  end

  # メンバー個別の新着ブログ表示（Atom）
  def test_index_feed_for_user_atom
    get :index_feed, :format => "atom"

    assert_template('feed.atom.builder')
    # puts @response.body
  end


  # ブログ記事検索
  def test_search
    logout

    BlogEntry.make(:title => "タイトル", :body => "テスト")
    BlogEntry.make(:title => "タイトル", :body => "テスト",
                   :visibility => BlogPreference::VISIBILITIES[:friend_only])

    post :search, :keyword => "テスト"

    assert_equal 1, assigns(:blog_entries).size
  end

  # ブログ記事検索（SNSメンバー）
  def test_search_for_member
    BlogEntry.make(:title => "タイトル", :body => "テスト")
    BlogEntry.make(:title => "タイトル", :body => "テスト",
                   :visibility => BlogPreference::VISIBILITIES[:friend_only])

    post :search, :keyword => "テスト"

    assert_equal 2, assigns(:blog_entries).size
  end

  # ブログ記事検索
  def test_search_for_user
    logout

    entry = BlogEntry.make(:title => "タイトル", :body => "テスト", :user_id => @current_user.id)

    post :index_for_user, :keyword => "テスト", :user_id => @current_user.id

    assert_equal 1, assigns(:blog_entries).size
  end

  # トモダチブログ記事検索
  def test_search_for_friends
    friend = User.make
    @current_user.friend!(friend)
    friend_blog = BlogEntry.make(:user => friend, :title => "test_search")
    BlogEntry.make(:title => "test_search")

    post :search_for_friends, :keyword => "test_search"

    assert_equal 1, assigns(:blog_entries).size
  end

  # ブログ投稿画面表示
  def test_new
    get :new
    assert_response :success
    assert_template "form"
  end

  # 新規投稿ブログ確認画面
  def test_confirm_before_create
    post :confirm_before_create,
    :blog_entry => BlogEntry.plan(:blog_attachments_attributes => { "0" => BlogAttachment.plan})

    assert_response :success
    assert_template "confirm"
    assert_not_nil assigns(:blog_entry)
    assert_not_nil session["blog_entries"][:unpublic_image_uploader_key]
  end

  # 新規投稿ブログ確認画面表示失敗（バリデーション）
  def test_confirm_before_create_fail
    post :confirm_before_create, :blog_entry => BlogEntry.plan(:title => "")

    assert_response :success
    assert_template "form"
  end

  # 入力情報クリア（作成時）
  def test_confirm_before_create_clear
    post :confirm_before_create, :blog_entry => BlogEntry.plan, :clear => "Clear"

    assert_response :redirect
    assert_redirected_to new_blog_entry_path
  end

  # ブログの作成
  def test_create_blog_entry
    @request.session["blog_entries"] = {:unpublic_image_uploader_key => ["test"]}

    assert_difference('BlogEntry.count') do
      post :create, :blog_entry => BlogEntry.plan
    end

    entry = assigns(:blog_entry)
    assert_equal true, @current_user.has_role?(:blog_entry_author, entry)

    assert_response :redirect
    assert_redirected_to complete_after_create_blog_entry_path(assigns(:blog_entry))
    assert_equal [], session["blog_entries"][:unpublic_image_uploader_key]
  end

  # ブログ作成キャンセル
  def test_create_blog_entry_cancel
    assert_difference('BlogEntry.count', 0) do
      post :create, :blog_entry => BlogEntry.plan, :cancel => "Cancel"
    end

    entry = assigns(:blog_entry)
    assert_equal false, @current_user.has_role?(:blog_entry_author, entry)

    assert_not_nil assigns(:blog_entry)
    assert_template "form"
  end

  # ブログの作成失敗（バリデーション）
  def test_create_blog_entry_fail
    assert_difference('BlogEntry.count', 0) do
      post :create, :blog_entry => BlogEntry.plan(:title => "")
    end

    entry = assigns(:blog_entry)
    assert_equal false, @current_user.has_role?(:blog_entry_author, entry)

    assert_template "form"
  end

  # ブログ記事表示
  def test_show_blog_entry
    logout
    entry = BlogEntry.make(:user => @current_user)

    get :show, :id => entry.id
    assert_response :success

    assert_equal 1, BlogEntry.find(entry.id).access_count
    assert_equal 1, assigns(:blog_entry).access_count
    assert_not_nil assigns(:blog_comments)
  end

  # ブログ記事表示（色々なタグ)
  def test_show_blog_entry_tag_mix
    logout
    entry =
      BlogEntry.make(:user => @current_user,
                     :body => <<-BODY)
    <EXT type="youtube" data="http://www.youtube.com/watch?v=ix2DeCzuckc">
    <PIC no="1">PIC1
    <b>bbbbb</b>
    <i>iiiii</i>
    <u>uuuuu</u>
    <font size="130%" color="red">130%のred</font>
    <hr>
    hr
    <PIC no="">
    BODY
    get :show, :id => entry.id
    assert_response :success
  end

  # ブログ編集画面
  def test_get_edit
    get :edit, :id => @update_record.id
    assert_response :success
    assert_template "form"
  end

  # ブログ編集確認画面
  def test_confirm_before_update
    @update_record.title = "update"
    post(:confirm_before_update, :id => @update_record.id,
         :blog_entry => @update_record.attributes)

    assert_response :success
    assert_template "confirm"
    assert_not_nil assigns(:blog_entry)
    assert_equal "update", assigns(:blog_entry).title
  end

  # ブログ編集確認画面表示失敗（バリデーション）
  def test_confirm_before_update_fail
    @update_record.title = ""
    post :confirm_before_update, :id => @update_record.id, :blog_entry => @update_record.attributes

    assert_response :success
    assert_template "form"
  end

  # 入力情報クリア（編集時）
  def test_confirm_before_update_fail_clear
    post :confirm_before_update, :id => @update_record.id,
         :blog_entry => @update_record.attributes,
         :clear => "Clear"

    assert_response :redirect
    assert_redirected_to edit_blog_entry_path(@update_record)
  end

  # ブログエントリ更新
  def test_update_blog_entry
    @update_record.title = "update"

    assert_difference('BlogEntry.count', 0) do
      put :update, :id => @update_record.id, :blog_entry => @update_record.attributes
    end

    assert_redirected_to complete_after_update_blog_entry_path(@update_record)
    assert_equal "update", assigns(:blog_entry).title
  end

  # ブログエントリ更新失敗（バリデーション）
  def test_update_blog_entry_fail
    @update_record.title = ""

    assert_difference('BlogEntry.count', 0) do
      put :update, :id => @update_record.id, :blog_entry => @update_record.attributes
    end

    assert_template "form"
    assert_equal "", assigns(:blog_entry).title
  end

  # ブログエントリ削除前画面表示
  def test_confirm_before_destroy
    get :confirm_before_destroy, :id => @update_record.id

    assert_template "confirm_before_destroy"
  end

  # ブログエントリ削除
  def test_destroy_blog_entry
    assert_difference('BlogEntry.count', -1) do
      delete :destroy, :id => @update_record.id
    end

    entry = assigns(:blog_entry)
    assert_equal false, @current_user.has_role?(:blog_entry_author, entry)

    assert_redirected_to index_for_user_user_blog_entries_path(:user_id => @current_user.id)
  end

  # ブログ記事所有者によるアクセス制限チェック
  def test_blog_entry_author_access
    entry = BlogEntry.make

    assert_raise Acl9::AccessDenied do
      post :edit, :id => entry.id, :blog_entry => entry.attributes
    end

    assert_raise Acl9::AccessDenied do
      post :confirm_before_update, :id => entry.id, :blog_entry => entry.attributes
    end

    assert_raise Acl9::AccessDenied do
      put :update, :id => entry.id, :blog_entry => entry.attributes
    end

    assert_raise Acl9::AccessDenied do
      post :complete_after_update, :id => entry.id, :blog_entry => entry.attributes
    end

    assert_raise Acl9::AccessDenied do
      delete :destroy, :id => entry.id
    end
  end

  # ブログエントリの公開範囲によるアクセス制限チェック
  def test_blog_entry_author_access
    entry = BlogEntry.make
    entry.user.preference.blog_preference.visibility = BlogPreference::VISIBILITIES[:friend_only]
    entry.user.preference.blog_preference.save!

    get :show, :id => entry.id
    assert_redirected_to not_friend_error_blog_entries_path

    @current_user.friend!(entry.user)
    get :show, :id => entry.id
    assert_response :success
  end

  # ブログエントリの公開範囲によるアクセス制限チェック
  def test_blog_entry_author_access_for_anonymous
    logout

    entry = BlogEntry.make
    entry.visibility = BlogPreference::VISIBILITIES[:friend_only]
    entry.save!
    assert_raise Mars::AccessDenied do
      get :show, :id => entry.id
    end
  end

  # ブログエントリの公開範囲によるアクセス制限チェック
  def test_index_for_user_access
    user = User.make
    user.preference.blog_preference.visibility = BlogPreference::VISIBILITIES[:friend_only]
    user.preference.blog_preference.save!

    get :index_for_user, :user_id => user.id
    assert_redirected_to not_friend_error_blog_entries_path

    @current_user.friend!(user)
    get :index_for_user, :user_id => user.id
    assert_response :success
  end

  # ブログエントリの公開範囲によるアクセス制限チェック
  def test_index_for_user_access_for_anonymous
    logout

    user = User.make
    user.preference.blog_preference.visibility = BlogPreference::VISIBILITIES[:friend_only]
    user.preference.blog_preference.save!

    assert_raise Mars::AccessDenied do
      get :index_for_user, :user_id => user.id
    end
  end

  # トモダチのみ閲覧可能な記事の閲覧
  def test_show_access_control_for_friend
    entry = BlogEntry.make(
              :visibility => BlogPreference::VISIBILITIES[:friend_only])
    entry.user.friend!(@current_user)
    @current_user.has_role!(:friend, entry.user)

    assert_nothing_raised Acl9::AccessDenied do
      get :show, :id => entry.id
    end
  end

  # 添付画像表示
  def test_show_unpublic_image
    entry = BlogEntry.make(:user => @current_user)
    attachment = BlogAttachment.make(:blog_entry_id => entry.id)

    assert_nothing_raised Mars::AccessDenied do
      assert_nothing_raised Acl9::AccessDenied do
        get :show_unpublic_image, :id => entry.id, :blog_attachment_id => attachment.id
      end
    end
  end

  # 添付画像表示
  def test_show_unpublic_image_temp
    attachment = BlogAttachment.new(BlogAttachment.plan)
    @request.session["blog_entries"] = {:unpublic_image_uploader_key => [attachment.image_temp]}

    assert_nothing_raised Mars::AccessDenied do
      assert_nothing_raised Acl9::AccessDenied do
        get :show_unpublic_image_temp, :image_temp => attachment.image_temp
      end
    end
  end

  # 添付画像表示（無名ユーザ）
  def test_show_unpublic_image_with_anonymous
    logout
    entry = BlogEntry.make(:user => @current_user)
    attachment = BlogAttachment.make(:blog_entry_id => entry.id)

    assert_nothing_raised Acl9::AccessDenied do
      get :show_unpublic_image, :id => entry.id, :blog_attachment_id => attachment.id
    end
  end

  # クチコミマップ表示
  def test_map
    entry = BlogEntry.make(:blog_category_id => BlogCategory.wom_id,
                           :latitude => 0.1, :longitude => 1, :zoom => 1)

    get :map

    assert_equal false, assigns(:blog_entries).empty?
    assert_not_nil assigns(:blog_entries).detect{|e| e == entry}
  end

  # クチコミマップ表示（RSS2）
  def test_map_rss2
    entry = BlogEntry.make(:blog_category_id => BlogCategory.wom_id,
                           :latitude => 0.1, :longitude => 1, :zoom => 1)

    get :map, :format => "rss"

    assert_template('feed.rxml')
    assert_not_nil assigns(:xml_title)
    assert_not_nil assigns(:xml_link)
    # puts @response.body
  end

  # クチコミマップ表示（RSS1.0）
  def test_map_rdf
    entry = BlogEntry.make(:blog_category_id => BlogCategory.wom_id,
                           :latitude => 0.1, :longitude => 1, :zoom => 1)

    get :map, :format => "rdf"

    assert_template('feed.rdf.builder')
    # puts @response.body
  end

  # クチコミマップ表示（Atom）
  def test_map_atom
    entry = BlogEntry.make(:blog_category_id => BlogCategory.wom_id,
                           :latitude => 0.1, :longitude => 1, :zoom => 1)

    get :map, :format => "atom"

    assert_template('feed.atom.builder')
    # puts @response.body
  end

  # クチコミマップ表示（モバイル用）
  def test_map_for_mobile
    entry = BlogEntry.make(:blog_category_id => BlogCategory.wom_id,
                           :latitude => 200, :longitude => 500, :zoom => 1)

    get(:map_for_mobile, :latitude => 200, :longitude => 450, :span_lat => 250, :span_lng => 250)

    assert_response(:success)
    assert_template('map_for_mobile')

    assert_equal false, assigns(:records).empty?
  end

  # 以前のアドレスでアクセスがあった場合のマッピング
  def test_assert_routing_for_old_url
    # ブログトップ
    assert_routing '/blog', :controller => 'blog_entries', :action => 'relate_old_user_id_to_current'

    # ブログ
    assert_routing '/blog/blog.php', :controller => 'blog_entries', :action => 'relate_old_blog_id_to_current'

    # クチコミマップのRSS2.0
    assert_recognizes({ :controller => 'blog_entries', :action => 'map', :format => 'rss' }, '/blog/feed/rss.php')
  end

  # 以前のユーザのブログトップURLでアクセスがあったとき
  def test_relate_old_user_id_to_current
    friend = User.make(:old_id => 1)
    @current_user.friend!(friend)
    friend_blog = BlogEntry.make(:user => friend)

    get :relate_old_user_id_to_current, :key => friend.old_id

    assert_redirected_to index_for_user_user_blog_entries_path(:user_id => friend.id)
  end

  # 以前のユーザのブログトップURLでアクセスがあったが、該当ユーザが存在しないとき
  def test_relate_old_user_id_to_current_but_nonexist
    assert_raise ActiveRecord::RecordNotFound do
      get :relate_old_user_id_to_current, :key => 0
    end
  end

  # 以前のブログのURLでアクセスがあったとき
  def test_relate_old_blog_id_to_current
    friend = User.make(:old_id => 1)
    @current_user.friend!(friend)
    friend_blog = BlogEntry.make(:user => friend, :old_id => 1)

    get :relate_old_blog_id_to_current, :key => friend_blog.old_id

    assert_redirected_to blog_entry_path(friend_blog)
  end

  # 以前のブログのURLでアクセスがあったが、該当ブログが存在しないとき
  def test_relate_old_blog_id_to_current_but_nonexist
    assert_raise ActiveRecord::RecordNotFound do
      get :relate_old_blog_id_to_current, :key => 0
    end
  end
end
