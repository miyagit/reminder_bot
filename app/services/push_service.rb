class PushService
  def self.reminder_schdules_push
    @reminder_schedules = Reminder.all
    @reminder_schedules.each do |reminder_schedule|
      if reminder_schedule.scheduled_at.to_s(:datetime) == Time.now.to_s(:datetime)
        pushToken = reminder_schedule.line_id
        output_text = reminder_schedule.scheduled_at.to_s(:datetime) + 'に' + reminder_schedule.remind_content
        client = LineClient.new(ENV.fetch("LINE_PRODUCTION_API_KEY"), ENV.fetch("OUTBOUND_PROXY"))
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
