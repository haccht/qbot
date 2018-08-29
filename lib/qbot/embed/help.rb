require 'stringio'

module Qbot

  class Help < Qbot::Base

    on /^#{prefix}help$/ do
      names = Qbot.app.bots
        .reject { |n| %w(Qbot::Base Qbot::Help).include?(n) }
        .map    { |n| n.split('::').last.downcase }

      next if names.empty?
      resp = StringIO.new
      resp.puts 'Features:'
      resp.puts names.map { |name| "  #{name}" }

      post resp.string
    end

  end

end
