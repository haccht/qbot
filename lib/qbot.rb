require 'Qbot/base'
require 'Qbot/autorun'

module Qbot

  module Delegator

    def self.delegate(*names)
      names.each do |name|
        define_method(name) do |*args, &block|
          MSbot::Base.send(name, *args, &block)
        end
      end
    end
    delegate :on

  end

end

extend MSbot::Delegator
