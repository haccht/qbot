module Qbot

  class Ping < Qbot::Base

    on /^ping\b/i do |msg|
      post msg[0].tr('iI', 'oO')
    end

  end

end
