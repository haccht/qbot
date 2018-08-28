require 'qbot/app'
require 'qbot/adapter'
require 'qbot/storage'

module Qbot

  class Base

    class << self

      def on(pattern, &block)
        pattern = Regexp.new(pattern.to_s) unless Regexp === pattern
        Qbot.app.bots.push(new(pattern, &block))
      end

      def usage(text)
        on(/^#{prefix}help\s+#{name.downcase}\b/) { post(text) }
      end

      private
      def prefix
        "#{ENV['QBOT_PREFIX']}\s+" if ENV['QBOT_PREFIX']
      end

    end

    def initialize(pattern, &block)
      @pattern  = pattern
      @callback = block
    end

    def call(message)
      return unless @pattern =~ message.to_s.strip
      instance_exec($~, &@callback)
    end

    def post(message, **options)
      Qbot.app.adapter.post(message, **options)
    end

    def cache
      Qbot.app.storage.namespace(self.class.name)
    end

  end

end
