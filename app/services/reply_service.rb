class ReplyService

  attr_reader :query_params

  def initialize(params)
    @query_params = params || {}
  end

  def cancel_escape(line_text)
    if line_text == "キャンセル"
      $remind_content = nil
      throw :escape
    end
  end

  def remind_create_content(id_belongs, event, line_text)
    event_type = event["type"]
    line_id = id_belongs["groupId"] || id_belongs["userId"]

    case event_type
    when "message"
      remind_schedule = line_text
      if dily_include?(remind_schedule) == "true"
        /日/ =~ remind_schedule
        daily_time = daily_change(Regexp.last_match.pre_match) + ' ' + Regexp.last_match.post_match.insert(2, ":")
        Reminder.create(line_id: line_id, scheduled_at: daily_time, remind_content: $remind_content)
        remind_schedule = Time.parse(daily_time).to_s(:datetime) + 'に' + $remind_content
      else
        begin
          scheduled_at = Time.parse(line_text)
          if scheduled_at
            Reminder.create(line_id: line_id, scheduled_at: remind_schedule, remind_content: $remind_content)
            remind_schedule = scheduled_at.to_s(:datetime) + 'に' + $remind_content
          end
        rescue => e
          if e
            remind_schedule = "あなたが入力したモノはフォーマットには不備があります。正しいフォーマットで入力して下さい(例: 2017/08/30 10:00)"
          end
        end
      end
    end
  end

  def delete_remind(id_belongs)
    line_id = id_belongs["groupId"] || id_belongs["userId"]
    latest = Reminder.where(line_id: line_id).order('created_at DESC').first
    if latest
      Reminder.destroy(Reminder.where(line_id: line_id, created_at: latest.created_at).ids)
      delete_judge_text =  latest.remind_content + '(' + latest.scheduled_at.to_s(:datetime) + ')のリマインドを取り消しました'
    else
      delete_judge_text = 'リマインドは登録されていませんでした。'
    end
  end

  def daily_change(unformed_datetime)
    case unformed_datetime
    when '今'
      return Time.now.to_s(:date)
    when '明'
      return Time.now.tomorrow.to_s(:date)
    when '明後'
      return Time.now.tomorrow.tomorrow.to_s(:date)
    when '明々後'
      return Time.now.tomorrow.tomorrow.tomorrow.to_s(:date)
    end
  end

  def dily_include?(japanese_date)
    dailys = ["今日", "明日", "明後日", "明々後日"]
    dailys.each do |daily|
      if japanese_date.include?(daily)
        return "true"
      end
    end
  end

end
