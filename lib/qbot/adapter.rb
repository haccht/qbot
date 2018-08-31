module Qbot

  Message = Struct.new(:text, :data, :matched)

  module Adapter

    class Driver

      class << self

        def inherited(subclass)
          @target = subclass
        end

        def build
          @target.new
        end

      end

      def run(bots)
        on_message do |message|
          bots.each { |bot| bot.call(message.dup) }
        end
      end

      def on_message(&block)
        raise 'Not implemented'
      end

      def post(text, **options)
        raise 'Not implemented'
      end

      def reply_to(message, text, **options)
        raise 'Not implemented'
      end

    end

  end

end
