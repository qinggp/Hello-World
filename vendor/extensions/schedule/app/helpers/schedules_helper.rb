# スケジュールヘルパ
module SchedulesHelper

  # 確認画面のForm情報
  def form_params
    if @schedule.new_record?
      {:url => confirm_before_create_new_schedule_path,
        :model_instance => @schedule}
    else
      {:url => confirm_before_update_schedule_path(:id => @schedule.id),
        :model_instance => @schedule}
    end
  end

  # 登録・編集画面のForm情報
  def confirm_form_params
    if @schedule.new_record?
      {:url => schedules_path, :method => :post,
        :model_instance => @schedule}
    else
      {:url => schedule_path(@schedule), :method => :put,
        :model_instance => @schedule}
    end
  end

  # 年齢を計算するメソッド
  def age(date, birthday)
    date = Date.parse(date) if date.is_a?(String)
    birthday = Date.parse(birthday) if birthday.is_a?(String)
    (date.strftime("%Y%m%d").to_i - birthday.strftime("%Y%m%d").to_i) / 10000
  end
end
