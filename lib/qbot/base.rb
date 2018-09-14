require 'dotenv/load'
require 'parse-cron'

require 'qbot/app'
require 'qbot/adapter'
require 'qbot/adapter/shell'
require 'qbot/storage'
require 'qbot/storage/memory'

module Qbot

  class Base

    class << self

      def on(pattern, &block)
        pattern = Regexp.new(pattern.to_s) unless Regexp === pattern
        Qbot.app.add(new(pattern, &block))
      end

      def cron(pattern, &block)
        schedule(pattern, &block)
      end

      private
      def schedule(pattern, &block)
        parser  = CronParser.new(pattern)
        current = Time.now
        delay   = parser.next(current) - current

        Qbot.app.timers.after(delay) do
          new(pattern).instance_eval(&block)
          schedule(pattern, &block)
        end
      end

    end

    def initialize(pattern, &block)
      @pattern  = pattern
      @callback = block
    end

    def call(message)
      @message = message
      return unless @pattern =~ @message.text.to_s.strip

      begin
        Qbot.app.logger.debug("#{self.class} - Recieve message: '#{message.text}'")
        instance_exec($~, &@callback)
      rescue => e
        Qbot.app.logger.error("#{self.class} - Error: #{e}")
      end
    end

    def post(text, **options)
      Qbot.app.adapter.reply_to(@message, text, **options)
    end

    def cache
      Qbot.app.storage.namespace(self.class.name)
    end

  end

end
