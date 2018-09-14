module Qbot

  def self.autorun
    at_exit do
      exit if $!

      %i{INT TERM}.each do |signal|
        Signal.trap(signal) { exit }
      end

      Qbot.run!(ARGV)
    end
  end

end

Qbot.autorun
