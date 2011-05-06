# ブログコメント管理
#
# ブログエントリ表示部分にコメント登録・修正・削除があるため
# viewのほとんどはブログエントリの部分テンプレートを使用しています。
class BlogCommentsController < ApplicationController
  include Mars::CalendarViewable

  before_filter :check_spam_ip_address, :only => %w(confirm_before_create create)
  before_filter :set_blog_entry_and_comment
  before_filter :set_user
  before_filter :set_blog_title

  with_options :redirect_to => :root_url do |con|
    con.verify :params => "blog_entry_id"
    con.verify :params => "id", :only => %w(destroy confirm_before_update)
    con.verify :params => "blog_comment",
      :only => %w(confirm_before_create confirm_before_update)
    con.verify :method => :post, :only => %w(confirm_before_create confirm_before_update create)
    con.verify :method => :put, :only => %w(update)
    con.verify :method => :delete, :only => %w(destroy)
  end

  access_control do
    allow all, :if => :deletable_user?, :to => %w(confirm_before_destroy destroy)
    allow all, :if => :editable_user?,
               :to => %w(edit confirm_before_update update complete_after_update)
    allow all, :if => :commentable_user?,
               :to => %w(new confirm_before_create create complete_after_create
                         show_calendar)

    # ブログエントリの公開範囲に応じたアクセス制限
    deny anonymous, :unless => :anonymous_viewable?
    deny logged_in, :unless => :member_viewable?
  end

  # コメント登録フォーム表示
  def new
    @blog_comment = BlogComment.new(:blog_entry_id => @blog_entry.id)
    render "form"
  end

  # 編集フォームの表示．
  def edit
    @blog_comment = BlogComment.find(params[:id])
    @blog_entry = @blog_comment.blog_entry
    render "form"
  end

  # 登録確認画面表示
  def confirm_before_create
    @blog_comment = BlogComment.new(
      BlogComment.default_attributes(params[:blog_comment], current_user, @blog_entry))
    if params[:clear]
      return redirect_to blog_entry_path(@blog_entry,
                           :anchor => @template.blog_comment_anchor_name)
    end

    if @blog_comment.valid?
      render "confirm"
    else
      logger.debug{ @blog_comment.to_yaml }
      render "form"
    end
  end

  # 編集確認画面表示
  def confirm_before_update
    @blog_comment = BlogComment.find(params[:id])
    @blog_comment.attributes = params[:blog_comment]
    if params[:clear]
      return redirect_to edit_blog_entry_blog_comment_path(@blog_entry, @blog_comment,
                           :anchor => @template.blog_comment_anchor_name)
    end

    if @blog_comment.valid?
      render "confirm"
    else
      logger.debug{ @blog_comment.to_yaml }
      render "form"
    end
  end

  # 登録データをDBに保存．
  def create
    @blog_comment = BlogComment.new(
      BlogComment.default_attributes(params[:blog_comment], current_user, @blog_entry))
    return render "form" if params[:cancel] || !@blog_comment.valid?

    BlogComment.transaction do
      @blog_comment.save!
    end

    comment_notification
    redirect_to complete_after_create_blog_entry_blog_comment_path(@blog_entry, @blog_comment, :anchor => @template.blog_comment_anchor_name)
  end

  # 登録後メッセージ表示
  def complete_after_create
    @blog_comment = BlogComment.find(params[:id])
    @blog_entry = @blog_comment.blog_entry
    @message = "コメント送信完了いたしました"
    render "complete"
  end

  # 更新データをDBに保存．
  def update
    @blog_comment = BlogComment.find(params[:id])
    @blog_entry = @blog_comment.blog_entry
    @blog_comment.attributes = params[:blog_comment]
    return render "form" if params[:cancel] || !@blog_comment.valid?

    BlogComment.transaction do
      @blog_comment.save!
    end

    comment_notification(true)
    redirect_to complete_after_update_blog_entry_blog_comment_path(@blog_entry, @blog_comment, :anchor => @template.blog_comment_anchor_name)
  end

  # 更新後メッセージ表示
  def complete_after_update
    @blog_comment = BlogComment.find(params[:id])
    @blog_entry = @blog_comment.blog_entry
    @message = "コメント修正完了いたしました"
    render "complete"
  end

  # レコードの削除
  def destroy
    @blog_comment = BlogComment.find(params[:id])
    @blog_entry = @blog_comment.blog_entry
    @blog_comment.destroy

    redirect_to blog_entry_path(@blog_entry)
  end

  private

  # コメント作成可能なユーザか？
  def commentable_user?
    @blog_entry.commentable?(current_user)
  end

  # 削除可能なユーザか
  def deletable_user?
    @blog_comment.deletable?(current_user)
  end

  # 変更可能なユーザか
  def editable_user?
    @blog_comment.editable?(current_user)
  end

  # @blog_entry,@blog_comment設定
  def set_blog_entry_and_comment
    @blog_entry = BlogEntry.find(params[:blog_entry_id])
    if params.has_key?(:id)
      @blog_comment = BlogComment.find(params[:id])
    end
  end

  # @title 設定
  def set_blog_title
    @title = @user.preference.blog_preference.title.dup
    if @blog_entry
      @title << " - #{@blog_entry.title}"
    end
  end

  # @user 設定
  def set_user
    if @blog_entry
      @user = User.find(@blog_entry.user_id)
    end
  end

  # 匿名ユーザは閲覧可能か？
  def anonymous_viewable?
    @blog_entry.anonymous_viewable?
  end

  # ブログ所持者、もしくはSNSメンバが閲覧可能か？
  def member_viewable?
    return true if @blog_entry.user_id == current_user.id
    @blog_entry.member_viewable? || firend_viewable?
  end

  # トモダチは閲覧可能か？
  def firend_viewable?
    current_user.friend_user?(@user) && @blog_entry.friend_viewable?
  end

  # コメントお知らせメール送信
  def comment_notification(edited=false)
    if(@user.id != current_user.try(:id) &&
       @user.preference.blog_preference.comment_notice_acceptable?)
      BlogCommentNotifier.
        deliver_notification(:blog_comment => @blog_comment,
                             :blog_entry => @blog_comment.blog_entry,
                             :edited => edited)
    end
  end
end
