require 'qbot/adapter/shell'
require 'qbot/storage/memory'
require 'qbot/embed/help'

module Qbot

  def self.autorun
    at_exit do
      exit if $!

      %i{INT TERM}.each do |signal|
        Signal.trap(signal) { exit }
      end

      Qbot.app.run(ARGV)
    end
  end

end

Qbot.autorun
