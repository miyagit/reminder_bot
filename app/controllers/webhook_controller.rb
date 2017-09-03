class WebhookController < ApplicationController
  protect_from_forgery with: :null_session

  CHANNEL_SECRET = ENV['CHANNEL_SECRET']
  OUTBOUND_PROXY = ENV['OUTBOUND_PROXY']
  CHANNEL_ACCESS_TOKEN = ENV['CHANNEL_ACCESS_TOKEN']

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
        rescue = e
          if e
            input_text = "ラーメンと入力し、ラーメンを食べに行く予定を決めましょう。"
          else
            Ramen.create(user_id: user_id, scheduled_at: scheduled_at)
            input_text = "hogehoge"
          end
        end
      end
      puts "----------------------------------"
      puts input_text
      output_text = input_text
    end

    client = LineClient.new(CHANNEL_ACCESS_TOKEN, OUTBOUND_PROXY)
    res = client.reply(replyToken, output_text)
    puts "----------------------------------"
    puts replyToken
    puts "----------------------------------"

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
    hash = OpenSSL::HMAC::digest(OpenSSL::Digest::SHA256.new, CHANNEL_SECRET, http_request_body)
    signature_answer = Base64.strict_encode64(hash)
    signature == signature_answer
  end
end
