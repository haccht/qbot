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
        on_message do |message|
          bots.each { |bot| bot.call(message) }
        end
      end

      def post(message, **opts)
        raise 'Not implemented'
      end

      def on_message(&block)
        raise 'Not implemented'
      end

    end

  end

end
