class ReplyService

  attr_reader :replyToken, :line_text, :line_id, :event_type

  @@remind_content = nil

  def post_remind_content
    @@remind_content = line_text
  end

  def get_remind_content
    @@remind_content
  end

  def initialize(params)
    @replyToken = params["events"][0]["replyToken"]
    @line_text = params["events"][0]["message"]["text"]
    @line_id = params["webhook"]["events"][0]["source"]["roomId"] || params["webhook"]["events"][0]["source"]["groupId"] || params["webhook"]["events"][0]["source"]["userId"]
    @event_type = params["events"][0]["type"]
  end

  def cancel_escape
    if line_text == "キャンセル"
      cancel_reply = @@remind_content + 'のリマインド登録をキャンセルしました。'
      reply_message(cancel_reply)
      @@remind_content = nil
      throw :escape
    end
  end

  def remind_create_content

    case event_type
      when "message"
        remind_schedule = line_text
        if remind_datetime = ja_to_date
          remind_schedule = reminder_create(line_id, remind_datetime)
        elsif daily_include?(remind_schedule) == "true"
          /日/ =~ remind_schedule
          daily_time = daily_change(Regexp.last_match.pre_match) + ' ' + Regexp.last_match.post_match.insert(2, ":")
          remind_schedule = reminder_create(line_id, daily_time)
        else
          begin
            scheduled_at = Time.parse(line_text)
            if scheduled_at
              if line_text.include?("時") || line_text.include?("分")
                remind_schedule = "時・分が入っている場合のリマインド登録はできないワン。正しいフォーマットで入力して下さい(例: 2017/08/30 10:00)"
              else
                remind_schedule = reminder_create(line_id, remind_schedule)
              end
            end
          rescue => e
            if e
              remind_schedule = "それじゃわからないワン。 正しいフォーマットで入力して下さい(例: 2017/08/30 10:00)"
            end
          end
        end
        reply_message(remind_schedule)
    end
  end

  def delete_remind
    latest = Reminder.where(line_id: line_id, remind_status: 'sent').order('created_at DESC').first
    if latest
      Reminder.destroy(Reminder.where(line_id: line_id, created_at: latest.created_at).ids)
      delete_judge_text = latest.remind_content + '(' + latest.scheduled_at.to_s(:datetime) + ')のリマインドを取り消しました'
    else
      delete_judge_text = 'リマインドは登録されていませんでした。'
    end
    reply_message(delete_judge_text)
    @@remind_content = nil
  end

  def reply_message(reply_text)
    client = LineClient.new(ENV.fetch("LINE_PRODUCTION_API_KEY"), ENV.fetch("OUTBOUND_PROXY"))
    res = client.reply(replyToken, reply_text)
    if res.status == 200
      Rails.logger.info({success: res})
    else
      Rails.logger.error({fail: res})
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
      elsif japanese_date.include?("時") || japanese_date.include?("分")
        return false
      elsif japanese_date.include?(daily)
        return "true"
      end
    end
  end

  def ja_to_date
    if line_text.length == 4 && line_text.to_i != 0
      line_time = Time.now.to_s(:date) + ' ' + line_text.insert(2, ":")
      line_tomorrow_time = Time.now.tomorrow.to_s(:date) + ' ' + line_text
      now_time = Time.now.to_s(:datetime)
      now_time < line_time ? line_time : line_tomorrow_time
    end
  end

  def reminder_create(line_id, scheduled_at)
    client = LineClient.new(ENV.fetch("LINE_PRODUCTION_API_KEY"), ENV.fetch("OUTBOUND_PROXY"))
    display_name = client.get_profile(line_id).body["displayName"]
    reminder = Reminder.new(line_id: line_id, scheduled_at: scheduled_at, display_name: display_name, remind_content: @@remind_content)
    if reminder.save
      remind_schedule = "#{@@remind_content}の時間だワン♪"
      @@remind_content = nil
      return remind_schedule
    else
      reminder.errors.messages[:scheduled_at][0]
    end
  end

end
