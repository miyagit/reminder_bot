class PushService
  def self.reminder_schdules_push
    @reminder_schedules = Reminder.where(remind_status: 'unset')
    @reminder_schedules.each do |reminder_schedule|
      if reminder_schedule.scheduled_at.to_s(:datetime) == Time.now.to_s(:datetime)
        pushToken = reminder_schedule.line_id
        output_text = reminder_schedule.scheduled_at.to_s(:datetime) + 'に' + reminder_schedule.remind_content
        client = LineClient.new(ENV.fetch("LINE_PRODUCTION_API_KEY"), ENV.fetch("OUTBOUND_PROXY"))
        push = client.push(pushToken, output_text)
        if push.status == 200
          success_remind = Reminder.where(line_id: reminder_schedule.line_id, scheduled_at: reminder_schedule.scheduled_at, remind_content: reminder_schedule.remind_content).first
          success_remind.update(remind_status: 'sent')
          Rails.logger.info({success: push})
        else
          Rails.logger.error({fail: push})
        end
      end
    end
  end
end
