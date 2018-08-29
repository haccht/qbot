module Qbot

  class Echo < Qbot::Base

    on /^echo( .+)$/ do |msg|
      post(msg[1].strip)
    end

    usage <<~EOL
  Usage:
    `echo <text>` - Reflect the given <text>.
    EOL

  end

end
