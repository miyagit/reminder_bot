class WebhookController < ApplicationController
  protect_from_forgery with: :null_session

  def callback
    unless is_validate_signature
      render :nothing => true, status: 470
    end

    event = params["events"][0]
    event_type = event["type"]
    replyToken = event["replyToken"]
    if params["webhook"]["events"][0]["source"]["groupId"]
      line_id = params["webhook"]["events"][0]["source"]["groupId"]
    else
      line_id = params["webhook"]["events"][0]["source"]["userId"]
    end

    case event_type
    when "message"
      input_text = event["message"]["text"]
      if input_text == "ラーメン"
        input_text = "いつでしょうか？"
      elsif dily_include?(input_text) == "true"
        /日/ =~ input_text
        daily_time = daily_change(Regexp.last_match.pre_match) + ' ' + Regexp.last_match.post_match.insert(2, ":")
        Ramen.create(line_id: line_id, scheduled_at: daily_time)
        input_text = Time.parse(daily_time).to_s(:datetime) + 'にラーメン'
      else
        begin
          scheduled_at = Time.parse(event["message"]["text"])
          if scheduled_at
            Ramen.create(line_id: line_id, scheduled_at: input_text)
            input_text = scheduled_at.to_s(:datetime) + 'にラーメン'
          end
        rescue => e
          if e
            input_text = "あなたが入力したモノはformatに不備があります。ラーメンと入力し、正しいフォーマットで入力し(例: 2017/08/30 10:00)ラーメンを食べに行く予定を決めましょう。"
          end
        end
      end
      output_text = input_text
    end

    client = LineClient.new(ENV.fetch("LINE_PRODUCTION_API_KEY"), ENV.fetch("OUTBOUND_PROXY"))
    res = client.reply(replyToken, output_text)

    if res.status == 200
      logger.info({success: res})
    else
      logger.info({fail: res})
    end

    render :nothing => true, status: :ok
  end

  private
  # verify access from LINE
  def is_validate_signature
    signature = request.headers["X-LINE-Signature"]
    http_request_body = request.raw_post
    hash = OpenSSL::HMAC::digest(OpenSSL::Digest::SHA256.new, ENV.fetch("LINE_PRODUCTION_API_SECRET"), http_request_body)
    signature_answer = Base64.strict_encode64(hash)
    signature == signature_answer
  end

  def daily_change(b)
    case b
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

  def dily_include?(c)
    dailys = ["今日", "明日", "明後日", "明々後日"]
    dailys.each do |daily|
      if c.include?(daily)
        return "true"
      end
    end
  end

end
