module Qbot

  class Ping < Qbot::Base

    on /^ping\b/i do |msg|
      post(msg.text.tr('iI', 'oO'))
    end

  end

end
