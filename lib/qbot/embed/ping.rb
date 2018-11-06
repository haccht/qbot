module Qbot

  class Ping < Qbot::Base

    on /\bping\b/i, global: true do |msg|
      post msg.captures[0].tr('iI', 'oO')
    end

  end

end
