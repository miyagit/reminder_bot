class Reminder < ApplicationRecord
  validate :start_end_check, on: :create

  enum remind_status: %w(unset sent)

  def start_end_check
    errors.add(:scheduled_at, "日付は、現在時刻よりも後の時間を記入して下さい。") unless
    Time.now < self.scheduled_at
  end
end
