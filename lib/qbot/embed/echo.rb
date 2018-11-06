module Qbot

  class Echo < Qbot::Base

    help "echo <text>" => "Echo back the given <text>."
    on /^echo( .+)$/ do |msg|
      post msg.captures[1].strip
    end

  end

end
