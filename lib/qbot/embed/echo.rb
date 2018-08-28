class Echo < Qbot::Base
  on /^echo( .+)$/ do |msg|
    post(msg[1].strip)
  end

  usage <<~EOL
  Usage:
    `echo <text>` - echo back given <text>.
  EOL
end
