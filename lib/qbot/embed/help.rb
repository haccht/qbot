require 'stringio'

class Help < Qbot::Base
  on /^#{prefix}help$/ do
    names = Qbot.app.bots
      .map    { |n| n.class.name.split('::').last.downcase }
      .reject { |n| %w(base help).include?(n) }
      .uniq

    next if names.empty?
    resp = StringIO.new
    resp.puts 'Features:'
    resp.puts names.map { |name| "  #{name}" }

    post resp.string
  end
end
