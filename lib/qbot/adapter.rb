require 'qbot/message'

module Qbot

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
        listen do |message|
          bots.each { |bot| bot.listen(message.dup) }
        end
      end

      def listen(&block)
        raise 'Not implemented'
      end

      def post(text, **options)
        raise 'Not implemented'
      end

    end

  end

end
