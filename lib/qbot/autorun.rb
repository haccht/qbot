require 'optparse'

module Qbot

  def self.autorun
    at_exit do
      exit if $!
      Qbot.app.run(ARGV)
    end
  end

end

Qbot.autorun
