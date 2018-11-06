require 'stringio'

module Qbot

  class Help < Qbot::Base

    on /^help\b/i do |msg|
      usage = Qbot.app.help_text

      text = StringIO.new
      text.puts 'Usage:'
      text.puts usage.map { |key, val| "`#{key}` - #{usage[key]}" }
      post text.string.chomp
    end

  end

end
