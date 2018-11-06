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
        Qbot.app.add_bot(new(pattern, **options, &block))
      end

      def cron(pattern, &block)
        schedule(pattern, &block)
      end

      def help(usages)
        Qbot.app.help_text(usages)
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
      if @options[:global]
        return unless message.match(@pattern)
      else
        return unless message.mentioned?
        return unless message.match(@pattern, prefix: message.mention)
      end

      Qbot.app.logger.debug("#{self.class} - Recieve message: '#{message.text}'")

      @message = message
      instance_exec(@message, &@callback)
    rescue => e
      Qbot.app.logger.error("#{self.class} - Error: #{e}")
    end

    def post(text, **options)
      Qbot.app.adapter.post(text, reply_to: @message, **options)
    end

    def cache
      Qbot.app.storage.namespace(self.class.name)
    end

  end

end
