require 'clockwork'
require File.expand_path('../boot', __FILE__)
require File.expand_path('../environment', __FILE__)
include Clockwork

LINE_PRODUCTION_API_SECRET = ENV.fetch("LINE_PRODUCTION_API_SECRET")
OUTBOUND_PROXY = ENV.fetch("OUTBOUND_PROXY")
LINE_PRODUCTION_API_KEY = ENV.fetch("LINE_PRODUCTION_API_KEY")
# 動作
handler do |job|
  case job
  when "remind.job"
    @reminder_schedules = Reminder.all
    @reminder_schedules.each do |reminder_schedule|
      if reminder_schedule.scheduled_at.to_s(:datetime) == Time.now.to_s(:datetime)
        pushToken = reminder_schedule.line_id
        output_text = reminder_schedule.scheduled_at.to_s(:datetime) + 'に' + reminder_schedule.remind_content
        client = LineClient.new(LINE_PRODUCTION_API_KEY, OUTBOUND_PROXY)
        push = client.push(pushToken, output_text)
        if push.status == 200
          Rails.logger.info({success: push})
        else
          Rails.logger.info({fail: push})
        end
      end
    end
  end
end

#スケジューリング
every(60.seconds, 'remind.job')
