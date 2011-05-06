require File.dirname(__FILE__) + '/../test_helper'

# スケジュール管理テスト
class SchedulesControllerTest < ActionController::TestCase
  def setup
    @current_user ||= User.make
    login_as(@current_user)
  end

  # 登録画面の表示
  def test_new
    get :new, :due_date => "2010/10/10"

    assert_response :success
    assert_template 'schedules/form'
    assert_kind_of Schedule, assigns(:schedule)
  end

  # 登録データ確認画面表示
  def test_confirm_before_create
    assert_no_difference(['Schedule.count']) do
      post :confirm_before_create,
           :schedule => Schedule.plan(:due_date => "2009/10/10")
    end

    assert_response :success
    assert_template 'schedules/confirm'
    assert_equal true, assigns(:schedule).valid?
  end

  # 登録データ確認画面表示
  # 開始時間が有効のとき
  def test_confirm_before_create_enabled_start_time
    start_time = Time.local(2010, 10, 10, 1, 1)
    end_time = Time.local(2010, 10, 10, 23, 59)

    assert_no_difference(['Schedule.count']) do
      post :confirm_before_create,
           :schedule => Schedule.plan(:due_date => "2009/10/10", :start_time => start_time,
                                      :end_time => end_time),
           :enabled_start_time => "yes"
    end

    schedule = assigns(:schedule)
    assert_equal schedule.start_time, start_time
    assert_nil schedule.end_time

    assert_response :success
    assert_template 'schedules/confirm'
    assert_equal true, assigns(:schedule).valid?
  end

  # 登録データ確認画面表示
  # 終了時間が有効のとき
  def test_confirm_before_create_enabled_end_time
    start_time = Time.local(2010, 10, 10, 1, 1)
    end_time = Time.local(2010, 10, 10, 23, 59)

    assert_no_difference(['Schedule.count']) do
      post :confirm_before_create,
           :schedule => Schedule.plan(:due_date => "2009/10/10", :start_time => start_time,
                                      :end_time => end_time),
           :enabled_end_time => "yes"
    end

    schedule = assigns(:schedule)
    assert_equal schedule.end_time, end_time
    assert_nil schedule.start_time

    assert_response :success
    assert_template 'schedules/confirm'
    assert_equal true, assigns(:schedule).valid?
  end

  # 登録データ確認画面表示失敗
  def test_confirm_before_create_fail

    assert_no_difference(['Schedule.count']) do
      post :confirm_before_create,
           :schedule => Schedule.plan(:due_date => "2010/10/100")
    end

    assert_response :success
    assert_template 'schedules/form'
    assert_equal false, assigns(:schedule).valid?
  end

  # 入力情報クリア（登録時）
  def test_confirm_before_create_clear
    post :confirm_before_create, :schedule => {}, :clear => "Clear"

    assert_response :redirect
    assert_redirected_to new_schedule_path
  end

  # 登録データの作成
  def test_create_schedule_enabled_start_and_end_time
    due_date = Date.civil(2010, 10, 10)
    start_time = Time.local(2010, 10, 10, 1, 1)
    end_time = Time.local(2010, 10, 10, 23, 59)

    attributes = Schedule.plan(:user_id => @current_user.id,
                               :due_date => due_date,
                               :start_time => start_time,
                               :end_time => end_time)

    assert_difference(['Schedule.count']) do
      post :create, :schedule => attributes, :enabled_start_time => "yes", :enabled_end_time => "yes"
    end

    schedule = assigns(:schedule)

    [:title, :detail, :public, :user_id].each do |attribute|
      assert_equal attributes[attribute], schedule.send(attribute)
    end

    assert_equal due_date, schedule.due_date
    assert_equal start_time, schedule.start_time
    assert_equal end_time, schedule.end_time

    assert_redirected_to complete_after_create_schedule_path(schedule)
  end

  # 登録データの作成キャンセル
  def test_create_schedule_cancel
    assert_no_difference(['Schedule.count']) do
      post :create, :schedule => Schedule.plan, :cancel => "Cancel"
    end

    assert_not_nil assigns(:schedule)
    assert_template 'schedules/form'
  end

  # 登録データ作成の失敗（バリデーション）
  def test_create_schedule_fail

    assert_no_difference(['Schedule.count']) do
      post :create, :schedule => Schedule.plan()
    end

    assert_template 'schedules/form'
  end

  # 編集画面の表示
  def test_edit
    get :edit, :id => Schedule.make(:valid, :author => @current_user).id

    assert_response :success
    assert_template 'schedules/form'
    assert_kind_of Schedule, assigns(:schedule)
  end

  # 編集データ確認画面表示
  def test_confirm_before_update
    post(:confirm_before_update, :id => Schedule.make(:valid, :author => @current_user).id,
         :schedule => Schedule.plan(:valid))

    assert_response :success
    assert_template 'schedules/confirm'
    assert_equal true, assigns(:schedule).valid?
  end

  # 編集データ確認画面表示
  # 開始時間が有効のとき
  def test_confirm_before_update_enabled_start_time
    post :confirm_before_update, :id => Schedule.make(:valid, :author => @current_user).id,
         :schedule => Schedule.plan(:valid),
         :enabled_start_time => "yes"

    schedule = assigns(:schedule)
    assert_equal Schedule.plan(:valid)[:start_time], schedule.start_time
    assert_nil schedule.end_time

    assert_response :success
    assert_template 'schedules/confirm'
    assert_equal true, assigns(:schedule).valid?
  end

  # 編集データ確認画面表示
  # 終了時間が有効のとき
  def test_confirm_before_update_enabled_end_time
    post :confirm_before_update, :id => Schedule.make(:valid, :author => @current_user).id,
         :schedule => Schedule.plan(:valid),
         :enabled_end_time => "yes"

    schedule = assigns(:schedule)
    assert_equal Schedule.plan(:valid)[:end_time], schedule.end_time
    assert_nil schedule.start_time

    assert_response :success
    assert_template 'schedules/confirm'
    assert_equal true, assigns(:schedule).valid?
  end

  # 編集データ確認画面表示失敗
  def test_confirm_before_update_fail
    post(:confirm_before_update, :id => Schedule.make(:valid, :author => @current_user).id,
        :schedule => Schedule.plan(:invalid))

    assert_response :success
    assert_template 'schedules/form'
    assert_equal false, assigns(:schedule).valid?
  end

  # 入力情報クリア（編集時）
  def test_confirm_before_update_clear
    entry = Schedule.make(:valid, :author => @current_user)
    post(:confirm_before_update, :id => entry.id,
        :schedule => Schedule.plan(:valid),
        :clear => "Clear")

    assert_response :redirect
    assert_redirected_to edit_schedule_path(entry)
  end

  # 編集データの更新
  def test_update_schedule
    record = Schedule.make(:valid, :author => @current_user)

    post_data = {
      :title => "test_title", :detail => "test_detail", :public => false,
      :due_date => Date.civil(2010, 10, 10), :start_time => Time.local(2010, 10, 10, 1, 1),
      :end_time => Time.local(2010, 10, 10, 23, 59)
    }

    assert_no_difference(['Schedule.count']) do
      put :update, :id => record.id, :schedule => post_data
    end

    schedule = assigns(:schedule)

    [:title, :detail, :public, :due_date, :start_time, :end_time].each do |a|
      assert_equal post_data[a], schedule.send(a)
    end

    assert_redirected_to complete_after_update_schedule_path(schedule)
  end

  # 編集データの作成キャンセル
  def test_update_schedule_cancel
    record = Schedule.make(:valid, :author => @current_user)

    put :update, :id => record.id, :schedule => Schedule.plan(:valid), :cancel => "Cancel"

    assert_not_nil assigns(:schedule)
    assert_template 'schedules/form'
  end

  # 編集データの更新の失敗（バリデーション）
  def test_update_schedule_fail
    record = Schedule.make(:valid, :author => @current_user)

    put :update, :id => record.id, :schedule => Schedule.plan(:invalid)

    attributes_before = record.attributes
    attributes_after = record.reload.attributes

    assert_equal attributes_before, attributes_after

    assert_template 'schedules/form'
  end

  # レコードの削除
  def test_destroy_schedule
    target_id = Schedule.make(:valid, :author => @current_user).id
    assert_difference('Schedule.count', -1) do
      delete :destroy, :id => target_id
    end

    assert_redirected_to show_calendar_schedules_path
  end

  # カレンダー表示
  def test_show_calendar
    get :show_calendar

    assert_response :success
    assert_template "schedules/show_calendar"
  end

  # ログインしていないと全てのアクションを叩くことができない
  def test_access_deny_accesses_without_login
    logout

    %w(show_calendar new show_list).each do |action|
      assert_raise Acl9::AccessDenied do
        get action
      end
    end
  end

  # ある日のスケジュール一覧を表示
  def test_show_list
    get :show_list, :date => "2009/10/10"

    assert_response :success
    assert_template "schedules/show_list"
  end

  # 他人が作成したスケジュールの編集、削除に関係する操作を行うことができないことをテスト
  def test_access_deny_because_of_schedule_created_by_other_user
    schedule = Schedule.make(:valid, :author => User.make)

    %w(edit complete_after_update).each do |action|
      assert_raise Acl9::AccessDenied do
        get action, :id => schedule.id
      end
    end

    assert_raise Acl9::AccessDenied do
      post :confirm_before_update, :id => schedule.id, :schedule => { }
    end

    assert_raise Acl9::AccessDenied do
      put :update, :id => schedule.id, :schedule => { }
    end

    assert_raise Acl9::AccessDenied do
      delete :destroy, :id => schedule.id
    end
  end

  # ある日の他人のスケジュールを表示した際に、自分のスケジュールが見えない、
  # かつ他人の公開スケジュールが見れることをテスト
  def test_show_list_for_other_schedule
    date = "2020/10/10"
    other = User.make

    my_public_schedule = Schedule.make(:due_date => date, :public => true,
                                       :author => @current_user)
    my_private_schedule = Schedule.make(:due_date => date, :public => false,
                                        :author => @current_user)
    other_public_schedule = Schedule.make(:due_date => date, :public => true,
                                          :author => other)
    other_private_schedule = Schedule.make(:due_date => date, :public => false,
                                          :author => other)

    get :show_list, :date => date, :user_id => other.id

    schedules = assigns(:schedules)
    assert_equal 1, schedules.size
    assert_equal other_public_schedule.id, schedules.first.id

    assert_response :success
    assert_template "schedules/show_list"
  end
end

