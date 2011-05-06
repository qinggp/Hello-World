# Schedules管理
#
# スケジュールモデルの表示、作成、編集削除を行う。
# また、スケジュールモデル以外にもトモダチの誕生日や参加するイベントの開催日
# をカレンダーに一覧表示する。
class SchedulesController < ApplicationController
  include Mars::CalendarViewable

  with_options :redirect_to => :schedules_url do |con|
    con.verify :params => "id", :only => %w(show destroy confirm_before_update confirm_before_destroy)
    con.verify :params => "schedule",
      :only => %w(confirm_before_create create confirm_before_update update)
    con.verify :method => :post, :only => %w(confirm_before_create confirm_before_update create)
    con.verify :method => :put, :only => %w(update)
    con.verify :method => :delete, :only => %w(destroy)
  end

  before_filter :load_schedule, :only => %w(edit confirm_before_update update confirm_before_update destroy confirm_before_destroy complete_after_update)

  before_filter :load_user


  access_control do
    allow logged_in
    deny all, :unless => :editable_user?,
              :to => %w(edit confirm_before_update update complete_after_update)
    deny all, :unless => :destroyable_user?,
              :to => %w(destroy confirm_before_destroy)
  end

  # 一覧の表示と並び替え，レコードの検索．
  def index
    @schedules = Schedule.by_activate_users.paginate(:all, paginate_options)
  end

  # レコードの詳細情報の表示．
  def show
    @schedule = Schedule.find(params[:id])
    @date = @schedule.due_date
  end

  # 登録フォームの表示．
  def new
    @schedule ||= Schedule.new(:due_date => params[:due_date] || Date.today.strftime("%Y/%m/%d"),
                               :public => true,
                               :author => current_user)
    render "form"
  end

  # 編集フォームの表示．
  def edit
    @schedule ||= Schedule.find(params[:id])
    render "form"
  end

  # 登録確認画面表示
  def confirm_before_create
    @schedule = Schedule.new(params[:schedule].merge(:author => current_user))
    check_enabled_time

    return redirect_to new_schedule_path(:due_date => params[:due_date]) if params[:clear]

    if @schedule.valid?
      render "confirm"
    else
      render "form"
    end
  end

  # 編集確認画面表示
  def confirm_before_update
    @schedule = Schedule.find(params[:id])
    @schedule.attributes = params[:schedule]
    check_enabled_time

    return redirect_to edit_schedule_path(@schedule) if params[:clear]

    if @schedule.valid?
      render "confirm"
    else
      render "form"
    end
  end

  # 登録データをDBに保存．
  def create
    @schedule = Schedule.new(params[:schedule].merge(:author => current_user))

    return render "form" if params[:cancel] || !@schedule.valid?

    Schedule.transaction do
      @schedule.save!
    end

    redirect_to complete_after_create_schedule_path(@schedule)
  end

  # 更新データをDBに保存．
  def update
    @schedule = Schedule.find(params[:id])
    @schedule.attributes = params[:schedule]
    return render "form" if params[:cancel] || !@schedule.valid?

    Schedule.transaction do
      @schedule.save!
    end

    redirect_to complete_after_update_schedule_path(@schedule)
  end

  # レコードの削除
  def destroy
    return redirect_to schedule_path(@schedule) if params.has_key?(:cancel)
    @schedule.destroy
    redirect_to show_calendar_schedules_path
  end

  # ある日のスケジュール一覧を表示
  def show_list
    @date = Date.parse(params[:date])
    sql = Schedule.sql_for_paginate(@date, @user, current_user)
    @schedules = Schedule.paginate_by_sql(sql,
                                          :page => params[:page],
                                          :per_page => params[:per_page])
  end

  # 削除確認画面
  def confirm_before_destroy
    render "confirm_before_destroy"
  end

  # コントローラ単位でのコンテンツホームのパスを返す
  def contents_home_path
    show_calendar_schedules_path
  end

  private
  # 一覧表示オプション
  def paginate_options
    return @paginate_options ||= {
      :page => (params[:page] ? sanitize_sql(params[:page]) : 1),
      :order => (params[:order] ? construct_sort_order : Schedule.default_index_order),
    }
  end

  # カレンダー表示に必要なパラメータ設定
  def set_calendar_params
    # 表示するスケジュールを取得する
    if  @user.id ==  current_user.id
      # 自分自身のスケジュール表示なら、公開制限に関わらず取得する
      @schedules = Schedule.user_id_is(@user.id)
    else
      # 他人のスケジュール表示なら、公開スケジュールのみ取得
      @schedules = Schedule.user_id_is(@user.id).public_is(true)
    end

    # その月で開催されるスケジュールを取得し、予定開始時間でソートする
    beginning_of_month = DateTime.new(@calendar_year, @calendar_month).beginning_of_month
    end_of_month = DateTime.new(@calendar_year, @calendar_month).end_of_month

    @schedules = @schedules.due_date_greater_than_or_equal_to(beginning_of_month).due_date_less_than_or_equal_to(end_of_month).ascend_by_start_time.ascend_by_id

    # ログインユーザと、表示するスケジュールのユーザが同じ場合は、誕生日の公開範囲が、「トモダチまで」以上
    # そうでない場合は、表示する誕生日の公開範囲が「公開」のみを表示
    if  @user.id ==  current_user.id
      @friends = User.by_birthday_visible_for_user(@user, false).ascend_by_id
    else
      @friends = User.by_birthday_visible_for_user(@user, true).ascend_by_id
    end
    @friends = @friends.by_birthday_on_month(@calendar_year, @calendar_month)

    # userが参加していて、かつコミュニティが非公開やないしょではなく、イベントが公開であるもの
    @events = @user.community_events.find(:all, :include => :community,
                                          :order => "community_threads.id",
                                          :conditions => ["communities.visibility NOT IN (?)",
                                                          [Community::VISIBILITIES[:secret],
                                                           Community::VISIBILITIES[:private]]])
  end

  # 編集可能かどうか
  def editable_user?
    @schedule.editable?(current_user)
  end

  # 削除可能かどうか
  def destroyable_user?
    @schedule.destroyable?(current_user)
  end

  # before_filterによって、アクション実行前に該当するscheduleモデルをロードする
  def load_schedule
    if params[:id] && Schedule.exists?(params[:id])
      @schedule = Schedule.find(params[:id])
    end
  end

  # スケジュールの所有者をロードする
  def load_user
    if params[:user_id] && User.exists?(params[:user_id])
      @user = User.find(params[:user_id])
    else
      @user = current_user
    end
  end

  # 開始時間と終了時間を設定するかどうかをチェックする
  def check_enabled_time
    @schedule.start_time = nil if params[:enabled_start_time].blank?
    @schedule.end_time = nil if params[:enabled_end_time].blank?
  end
end
