class WebhookController < ApplicationController
  protect_from_forgery with: :null_session

  def callback
    unless is_validate_signature
      render :nothing => true, status: 470
    end

    reply_service = ReplyService.new(params)
    replyToken = reply_service.query_params["events"][0]["replyToken"]
    line_text  = reply_service.query_params["events"][0]["message"]["text"]
    id_belongs = reply_service.query_params["webhook"]["events"][0]["source"]
    event = reply_service.query_params["events"][0]

    catch :escape do

      if reply_service.get_remind_content
        reply_service.cancel_escape(line_text)
        remind_schedule = reply_service.remind_create_content(id_belongs, event, line_text)
        reply_service.reply_message(replyToken, remind_schedule)
        reply_service.post_remind_content(nil)
      elsif line_text == "キャンセル"
        delete_judge_text = reply_service.delete_remind(id_belongs)
        reply_service.reply_message(replyToken, delete_judge_text)
        reply_service.post_remind_content(nil)
      else
        reply_service.post_remind_content(line_text)
        reply_service.reply_message(replyToken, "いつでしょうか？")
      end
    end

    render nothing: true, status: :ok
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

end
