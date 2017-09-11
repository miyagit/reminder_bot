class WebhookController < ApplicationController
  protect_from_forgery with: :null_session

  def callback
    unless is_validate_signature
      render :nothing => true, status: 470
    end

    reply_service = ReplyService.new(params)

    catch :escape do

      if reply_service.get_remind_content
        reply_service.cancel_escape
        reply_service.remind_create_content
      elsif reply_service.line_text == "キャンセル"
        reply_service.delete_remind
      else
        reply_service.post_remind_content
        reply_service.reply_message("いつでしょうか？")
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
