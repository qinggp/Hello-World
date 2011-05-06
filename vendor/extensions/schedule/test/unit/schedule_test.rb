require File.dirname(__FILE__) + '/../test_helper'

class ScheduleTest < ActiveSupport::TestCase

  # スケジュールを編集可能かどうかを返すメソッドのテスト
  def test_editable
    user = User.make
    schedule = Schedule.make(:valid, :author => user)

    assert schedule.editable?(user)
    assert !schedule.editable?(User.make)
  end

  # スケジュールを削除可能かどうかを返すメソッドのテスト
  def test_destroyable
    user = User.make
    schedule = Schedule.make(:valid, :author => user)

    assert schedule.destroyable?(user)
    assert !schedule.destroyable?(User.make)
  end

  def test_destroy_related_to_user_record
    schedule_count = Schedule.count
    user = nil
    2.times do
      user = User.make
      3.times do
        Schedule.make(:valid, :user_id => user.id)
      end
    end
    assert_equal schedule_count + 6, Schedule.count
    user.destroy
    assert_equal schedule_count + 3, Schedule.count
  end
end
