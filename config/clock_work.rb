require 'clockwork'
require File.expand_path('../boot', __FILE__)
require File.expand_path('../environment', __FILE__)
include Clockwork

# 動作
handler do |job|
  case job
  when "remind.job"
    PushService.reminder_schdules_push
  end
end

#スケジューリング
every(60.seconds, 'remind.job')
