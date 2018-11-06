require 'dotenv/load'
require 'parse-cron'

require 'qbot/app'
require 'qbot/message'
require 'qbot/adapter'
require 'qbot/adapter/shell'
require 'qbot/storage'
require 'qbot/storage/memory'

module Qbot

  class Base

    class << self

      def on(pattern, **options, &block)
        pattern  = Regexp.new("\b#{pattern}\b") unless Regexp === pattern
        instance = new(pattern, **options, &block)
        Qbot.app.add(instance)
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
          begin
            instance = new(pattern)
            instance.instance_eval(&block)
          rescue => e
            Qbot.app.logger.error("#{instance.class} - Error: #{e}")
          end

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
        return unless @pattern =~ message.text.strip
      else
        return unless message.mentioned?
        return unless @pattern =~ message.text.sub(/^#{message.mention}/, '').strip
      end

      Qbot.app.logger.debug("#{self.class} - Recieve message: '#{message.text}'")

      @message = message
      instance_exec($~, &@callback)
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
