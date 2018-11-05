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

      def on(pattern, **options, &block)
        pattern = Regexp.new("\b#{pattern}\b") unless Regexp === pattern
        Qbot.app.add(new(pattern, **options, &block))
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

    def initialize(pattern, **options, &block)
      @pattern  = pattern
      @options  = options
      @callback = block
    end

    def listen(message)
      return unless @options[:global] || !message.mentioned?
      return unless @pattern =~ message.text.to_s.strip
      Qbot.app.logger.debug("#{self.class} - Recieve message: '#{message.text}'")

      @message = message
      instance_exec($~, &@callback)
    rescue => e
      Qbot.app.logger.error("#{self.class} - Error: #{e}")
    end

    def post(text, **options)
      Qbot.app.adapter.reply_to(@message, text, **options)
    end

    def cache
      Qbot.app.storage.namespace(self.class.name)
    end

  end

end
