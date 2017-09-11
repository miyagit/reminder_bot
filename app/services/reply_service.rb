class ReplyService

  attr_reader :query_params
  @@remind_content = nil
  @@remind_false   = true

  def post_remind_content(remind_content)
    @@remind_content = remind_content
  end

  def get_remind_content
    @@remind_content
  end

  def initialize(params)
    @query_params = params || {}
  end

  def cancel_escape(line_text)
    if line_text == "キャンセル"
      cancel_reply = @@remind_content + 'のリマインド登録をキャンセルしました。'
      reply_message(query_params["events"][0]["replyToken"], cancel_reply)
      @@remind_content = nil
      throw :escape
    end
  end

  def remind_create_content(id_belongs, event, line_text)
    while @@remind_false
      event_type = event["type"]
      line_id = id_belongs["groupId"] || id_belongs["userId"]

      case event_type
      when "message"
        remind_schedule = line_text
        if remind_datetime = judge_only_nanji_nanhun(line_text)
          remind_schedule = reminder_create(line_id, remind_datetime, @@remind_content)
        elsif daily_include?(remind_schedule) == "true"
          /日/ =~ remind_schedule
          daily_time = daily_change(Regexp.last_match.pre_match) + ' ' + Regexp.last_match.post_match.insert(2, ":")
          remind_schedule = reminder_create(line_id, daily_time, @@remind_content)
        else
          begin
            scheduled_at = Time.parse(line_text)
            if scheduled_at
              remind_schedule = reminder_create(line_id, remind_schedule, @@remind_content)
            end
          rescue => e
            if e
              remind_schedule = "あなたが入力したモノはフォーマットには不備があります。正しいフォーマットで入力して下さい(例: 2017/08/30 10:00)"
            end
          end
        end
        reply_message(query_params["events"][0]["replyToken"], remind_schedule)
      end
    end
    post_remind_content(nil)
    @@remind_false = true
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
    reply_message(query_params["events"][0]["replyToken"], delete_judge_text)
    post_remind_content(nil)
  end

  def reply_message(replyToken, reply_text)
    client = LineClient.new(ENV.fetch("LINE_PRODUCTION_API_KEY"), ENV.fetch("OUTBOUND_PROXY"))
    res = client.reply(replyToken, reply_text)
    if res.status == 200
      Rails.logger.info({success: res})
    else
      Rails.logger.info({fail: res})
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

  def daily_include?(japanese_date)
    dailys = ["今日", "明日", "明後日", "明々後日"]
    dailys.each do |daily|
      if japanese_date == daily
        return false
      elsif japanese_date.include?(daily)
        return "true"
      end
    end
  end

  def judge_only_nanji_nanhun(line_text)
    if line_text.length == 4 && line_text.to_i != 0
      line_time = Time.now.to_s(:date) + ' ' + line_text.insert(2, ":")
      line_tomorrow_time = Time.now.tomorrow.to_s(:date) + ' ' + line_text
      now_time = Time.now.to_s(:datetime)
      now_time < line_time ? line_time : line_tomorrow_time
    end
  end

  def reminder_create(line_id, scheduled_at, remind_content)
    reminder = Reminder.new(line_id: line_id, scheduled_at: scheduled_at, remind_content: remind_content)
    if reminder.save
      @@remind_false = false
      Time.parse(scheduled_at).to_s(:datetime) + 'に' + remind_content
    else
      reminder.errors.messages[:scheduled_at][0]
    end
  end

end
