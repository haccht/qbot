require 'qbot/base'
require 'qbot/embed/help'
require 'qbot/autorun'

module Qbot

  module Delegator

    def self.delegate(*names)
      names.each do |name|
        define_method(name) do |*args, &block|
          Qbot::Base.send(name, *args, &block)
        end
      end
    end
    delegate :on, :cron

  end

end

extend Qbot::Delegator
