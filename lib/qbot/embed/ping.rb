class Ping < Qbot::Base
  on /^ping\b/i do |msg|
    post(msg.to_s.tr('iI', 'oO'))
  end
end
