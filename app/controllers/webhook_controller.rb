class WebhookController < ApplicationController
  protect_from_forgery with: :null_session

  LINE_PRODUCTION_API_SECRET = ENV.fetch("LINE_PRODUCTION_API_SECRET")
  OUTBOUND_PROXY = ENV.fetch("OUTBOUND_PROXY")
  LINE_PRODUCTION_API_KEY = ENV.fetch("LINE_PRODUCTION_API_KEY")

  def callback
    unless is_validate_signature
      render :nothing => true, status: 470
    end

    event = params["events"][0]
    event_type = event["type"]
    replyToken = event["replyToken"]
    user_id = params["webhook"]["events"][0]["source"]["userId"]

    case event_type
    when "message"
      input_text = event["message"]["text"]
      if input_text == "ラーメン"
        input_text = "いつでしょうか？"
      else
        begin
          scheduled_at = Time.parse(event["message"]["text"])
          if scheduled_at
            Ramen.create(user_id: user_id, scheduled_at: input_text)
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

    client = LineClient.new(LINE_PRODUCTION_API_KEY, OUTBOUND_PROXY)
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
    hash = OpenSSL::HMAC::digest(OpenSSL::Digest::SHA256.new, LINE_PRODUCTION_API_SECRET, http_request_body)
    signature_answer = Base64.strict_encode64(hash)
    signature == signature_answer
  end
end
