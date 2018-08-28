require 'qbot/adapter/shell'
require 'qbot/storage/memory'
require 'qbot/embed/help'

module Qbot

  def self.autorun
    at_exit do
      exit if $!
      Qbot.app.run(ARGV)
    end
  end

end

Qbot.autorun
