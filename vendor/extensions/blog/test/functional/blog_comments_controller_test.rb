require File.dirname(__FILE__) + '/../test_helper'

# ブログコメント管理テスト
class BlogCommentsControllerTest < ActionController::TestCase
  def setup
    setup_emails
    @anchor_name = "blog_comment"
    @current_user = User.make
    login_as(@current_user)
  end

  # 編集画面の表示
  def test_new
    get :new, :blog_entry_id => valid_blog_comment_plan[:blog_entry_id]

    assert_response :success
    assert_template 'blog_comments/form'
    assert_kind_of BlogComment, assigns(:blog_comment)
  end

  # 登録データ確認画面表示
  def test_confirm_before_create
    plan = valid_blog_comment_plan(:user_id => nil)
    assert_no_difference(['BlogComment.count']) do
      post :confirm_before_create, :blog_entry_id => plan[:blog_entry_id], :blog_comment => plan
    end

    assert_response :success
    assert_template 'blog_comments/confirm'
    assert_equal true, assigns(:blog_comment).valid?
    assert_equal @current_user.id, assigns(:blog_comment).user.id
  end

  # 登録データ確認画面表示（匿名ユーザ）
  def test_confirm_before_create_for_anonymous
    logout
    plan = valid_blog_comment_plan({}, :anonymous)

    assert_no_difference(['BlogComment.count']) do
      post :confirm_before_create, :blog_entry_id => plan[:blog_entry_id], :blog_comment => plan
    end

    assert_response :success
    assert_template 'blog_comments/confirm'
    assert_equal true, assigns(:blog_comment).valid?
    assert_equal true, assigns(:blog_comment).anonymous
  end

  # 登録データ確認画面表示（匿名ユーザでスパム判定）
  def test_confirm_before_create_for_malicious_anonymous
    logout
    plan = valid_blog_comment_plan({}, :anonymous)

    SpamIpAddress.make(:ip_address => @request.remote_ip)

    assert_no_difference(['BlogComment.count']) do
      post :confirm_before_create, :blog_entry_id => plan[:blog_entry_id], :blog_comment => plan
    end

    assert_response :missing
  end

  # 登録データ確認画面表示失敗
  def test_confirm_before_create_fail
    plan = valid_blog_comment_plan(:body => "", :user_id => "")
    assert_no_difference(['BlogComment.count']) do
      post :confirm_before_create,
           :blog_entry_id => plan[:blog_entry_id],
           :blog_comment => plan
    end

    assert_response :success
    assert_template 'blog_comments/form'
    assert_equal false, assigns(:blog_comment).valid?
  end

  # 入力情報クリア
  def test_confirm_before_create_clear
    plan = valid_blog_comment_plan(:user_id => nil)
    assert_no_difference(['BlogComment.count']) do
      post :confirm_before_create, :blog_entry_id => plan[:blog_entry_id],
           :blog_comment => plan, :clear => "Clear"
    end

    assert_redirected_to blog_entry_path(assigns(:blog_entry), :anchor => @anchor_name)
  end

  # 登録データの作成
  def test_create_blog_comment
    plan = valid_blog_comment_plan(:body => "create", :user_id => "")
    before_delivers = @emails.size

    assert_difference(['BlogComment.count']) do
      post :create, :blog_entry_id => plan[:blog_entry_id],
           :blog_comment => plan
    end

    @blog_comment = BlogComment.last
    assert_equal "create", @blog_comment.body
    assert_equal @current_user.id, @blog_comment.user_id
    assert_equal before_delivers+1, @emails.size

    assert_redirected_to complete_after_create_blog_entry_blog_comment_path(@blog_comment.blog_entry, @blog_comment, :anchor => @anchor_name)
  end

  # 登録データの作成（匿名ユーザ）
  def test_create_blog_comment_for_anonymous
    logout
    before_delivers = @emails.size

    plan = valid_blog_comment_plan({:body => "create"}, :anonymous)
    assert_difference(['BlogComment.count']) do
      post :create, :blog_entry_id => plan[:blog_entry_id],
           :blog_comment => plan
    end

    @blog_comment = BlogComment.last
    assert_equal "create", @blog_comment.body
    assert_equal true, @blog_comment.anonymous
    assert_equal before_delivers+1, @emails.size

    assert_redirected_to complete_after_create_blog_entry_blog_comment_path(@blog_comment.blog_entry, @blog_comment, :anchor => @anchor_name)
  end

  # 登録データの作成（匿名ユーザでスパム判定）
  def test_create_blog_comment_for_malicious_anonymous
    logout
    before_delivers = @emails.size

    plan = valid_blog_comment_plan({:body => "create"}, :anonymous)
    SpamIpAddress.make(:ip_address => @request.remote_ip)

    assert_no_difference(['BlogComment.count']) do
      post :create, :blog_entry_id => plan[:blog_entry_id],
           :blog_comment => plan
    end

    assert_response :missing
  end

  # 登録データの作成（自分の日記）
  def test_create_blog_comment_for_my_blog
    plan = valid_blog_comment_plan(:body => "create", :user_id => "")
    before_delivers = @emails.size

    # 自分の日記に設定
    entry = BlogEntry.find(plan[:blog_entry_id])
    entry.user = @current_user
    entry.save!

    assert_difference(['BlogComment.count']) do
      post :create, :blog_entry_id => plan[:blog_entry_id],
           :blog_comment => plan
    end

    @blog_comment = BlogComment.last
    assert_equal "create", @blog_comment.body
    assert_equal @current_user.id, @blog_comment.user_id
    assert_equal before_delivers, @emails.size

    assert_redirected_to complete_after_create_blog_entry_blog_comment_path(@blog_comment.blog_entry, @blog_comment, :anchor => @anchor_name)
  end

  # 登録データの作成キャンセル
  def test_create_blog_comment_cancel
    plan = valid_blog_comment_plan
    assert_no_difference(['BlogComment.count']) do
      post :create, :blog_entry_id => plan[:blog_entry_id], :blog_comment => plan, :cancel => "Cancel"
    end

    assert_not_nil assigns(:blog_comment)
    assert_template 'blog_comments/form'
  end

  # 登録データ作成の失敗（バリデーション）
  def test_create_blog_comment_fail
    plan = valid_blog_comment_plan(:body => "")
    assert_no_difference(['BlogComment.count']) do
      post :create, :blog_entry_id => plan[:blog_entry_id], :blog_comment => plan
    end

    assert_template 'blog_comments/form'
  end

  # 編集画面の表示
  def test_edit
    record = BlogComment.make(valid_blog_comment_plan)
    get :edit, :blog_entry_id => record.blog_entry_id, :id => record.id

    assert_response :success
    assert_template 'blog_comments/form'
    assert_kind_of BlogComment, assigns(:blog_comment)
  end

  # 編集データ確認画面表示
  def test_confirm_before_update
    record = BlogComment.make(valid_blog_comment_plan)
    post(:confirm_before_update, :blog_entry_id => record.blog_entry_id, :id => record.id,
        :blog_comment => valid_blog_comment_plan)

    assert_response :success
    assert_template 'blog_comments/confirm'
    assert_equal true, assigns(:blog_comment).valid?
    assert_equal @current_user.id, assigns(:blog_comment).user.id
  end

  # 編集データ確認画面表示失敗
  def test_confirm_before_update_fail
    record = BlogComment.make(valid_blog_comment_plan)
    post(:confirm_before_update, :blog_entry_id => record.blog_entry_id, :id => record.id,
        :blog_comment => valid_blog_comment_plan(:body => ""))

    assert_response :success
    assert_template 'blog_comments/form'
    assert_equal false, assigns(:blog_comment).valid?
  end

  # 入力情報クリア
  def test_confirm_before_update_clear
    record = BlogComment.make(valid_blog_comment_plan)
    post(:confirm_before_update, :blog_entry_id => record.blog_entry_id, :id => record.id,
        :blog_comment => valid_blog_comment_plan(:user_id => ""), :clear => "Clear")

    assert_response :redirect
    assert_redirected_to edit_blog_entry_blog_comment_path(assigns(:blog_entry), assigns(:blog_comment),
                                                :anchor => @anchor_name)
  end

  # 編集データの更新
  def test_update_blog_comment
    record = BlogComment.make(valid_blog_comment_plan)
    before_delivers = @emails.size

    assert_no_difference(['BlogComment.count']) do
      put :update, :blog_entry_id => record.blog_entry_id, :id => record.id,
          :blog_comment => valid_blog_comment_plan(:body => "update", :blog_entry_id => record.blog_entry_id)
    end

    @blog_comment = BlogComment.last
    assert_equal "update", @blog_comment.body
    assert_equal @current_user.id, @blog_comment.user_id
    assert_equal false, @emails.empty?
    assert_equal before_delivers+1, @emails.size

    assert_redirected_to complete_after_update_blog_entry_blog_comment_path(@blog_comment.blog_entry_id, @blog_comment,:anchor => @anchor_name)
  end

  # 編集データの更新
  def test_update_blog_comment_for_my_blog
    record = BlogComment.make(valid_blog_comment_plan)
    before_delivers = @emails.size

    # 自分の日記に設定
    entry = record.blog_entry
    entry.user = @current_user
    entry.save!

    assert_no_difference(['BlogComment.count']) do
      put :update, :blog_entry_id => record.blog_entry_id, :id => record.id,
          :blog_comment => valid_blog_comment_plan(:body => "update", :blog_entry_id => record.blog_entry_id)
    end

    assert_equal before_delivers, @emails.size
  end

  # 編集データの作成キャンセル
  def test_update_blog_comment_cancel
    record = BlogComment.make(valid_blog_comment_plan)

    put :update, :blog_entry_id => record.blog_entry_id, :id => record.id,
        :blog_comment => valid_blog_comment_plan, :cancel => "Cancel"

    assert_not_nil assigns(:blog_comment)
    assert_template 'blog_comments/form'
  end

  # 編集データの更新の失敗（バリデーション）
  def test_update_blog_comment_fail
    record = BlogComment.make(valid_blog_comment_plan)
    before_body = record.body

    put :update, :blog_entry_id => record.blog_entry_id, :id => record.id,
        :blog_comment => valid_blog_comment_plan(:body => "")

    assert_equal before_body, BlogComment.find(record.id).body
    assert_template 'blog_comments/form'
  end

  # 削除確認画面表示
  def test_confirm_before_destroy
    record = BlogComment.make(valid_blog_comment_plan)
    entry_id = record.blog_entry.id

    get :confirm_before_destroy, :blog_entry_id => record.blog_entry_id, :id => record.id

    assert_template "confirm_before_destroy"
  end

  # レコードの削除
  def test_destroy_blog_comment
    record = BlogComment.make(valid_blog_comment_plan)
    entry_id = record.blog_entry.id
    assert_difference('BlogComment.count', -1) do
      delete :destroy, :blog_entry_id => record.blog_entry_id, :id => record.id
    end

    assert_redirected_to blog_entry_path(:id => entry_id)
  end

  # 作成後完了画面表示
  def test_complete_after_create
    record = BlogComment.make(valid_blog_comment_plan)
    get :complete_after_create, :blog_entry_id => record.blog_entry_id,
         :id => record.id

    assert_not_nil assigns(:blog_comment)
    assert_not_nil assigns(:blog_entry)
    assert_template "blog_comments/complete"
  end

  # 更新後完了画面表示
  def test_complete_after_update
    record = BlogComment.make(valid_blog_comment_plan)
    get :complete_after_update, :blog_entry_id => record.blog_entry_id, :id => record.id

    assert_not_nil assigns(:blog_comment)
    assert_not_nil assigns(:blog_entry)
    assert_template "blog_comments/complete"
  end

  # 作成アクションに対してアクセス制限チェック
  def test_create_access_check
    entry = BlogEntry.make(:comment_restraint => BlogPreference::VISIBILITIES[:unpubliced])
    entry.user.preference.blog_preference = BlogPreference.make
    entry.user.preference.save!
    plan = valid_blog_comment_plan(:blog_entry_id => entry.id)

    assert_raise Acl9::AccessDenied do
      post :confirm_before_create, :blog_entry_id => entry.id, :blog_comment => plan
    end

    assert_raise Acl9::AccessDenied do
      post :create, :blog_entry_id => entry.id, :blog_comment => plan
    end
  end

  # 削除アクションに対してアクセス制限チェック
  def test_destroy_access_check
    record = BlogComment.make(valid_blog_comment_plan(:user => User.make))

    assert_raise Acl9::AccessDenied do
      delete :destroy, :blog_entry_id => record.blog_entry_id, :id => record.id
    end
  end

  # 更新アクションに対してアクセス制限チェック
  def test_update_access_check
    other_user = User.make
    record = BlogComment.make(valid_blog_comment_plan(:user => other_user))

    assert_raise Acl9::AccessDenied do
      post :edit, :blog_entry_id => record.blog_entry_id, :id => record.id
    end

    assert_raise Acl9::AccessDenied do
      post :confirm_before_update, :blog_entry_id => record.blog_entry_id, :id => record.id, :blog_comment => record.attributes
    end

    assert_raise Acl9::AccessDenied do
      put :update, :blog_entry_id => record.blog_entry_id, :id => record.id, :blog_comment => record.attributes
    end

    assert_raise Acl9::AccessDenied do
      post :complete_after_update, :blog_entry_id => record.blog_entry_id, :id => record.id
    end
  end

  # トモダチのみ閲覧可能な記事の閲覧
  def test_show_access_control_for_friend
    entry = BlogEntry.make(
              :visibility => BlogPreference::VISIBILITIES[:friend_only])
    entry.user.friend!(@current_user)
    @current_user.has_role!(:friend, entry.user)

    assert_nothing_raised Acl9::AccessDenied do
      get :new, :blog_entry_id => entry.id
    end
  end

  private

  def valid_blog_comment_plan(attrs={}, plan_type=nil)
    plan = plan_type.nil? ?
           BlogComment.plan(:user => @current_user) :
           BlogComment.plan(plan_type)
    user = BlogEntry.find(plan[:blog_entry_id]).user
    user.preference.blog_preference = BlogPreference.make(:comment_notice_acceptable => true)
    user.preference.save!
    plan.merge(attrs)
  end
end
