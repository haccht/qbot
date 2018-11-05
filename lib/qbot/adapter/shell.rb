require 'eventmachine'

module Qbot

  module Adapter

    class Shell < Qbot::Adapter::Driver

      module Keyboard

        include EM::Protocols::LineText2

        def initialize(callback)
          @callback = callback
          $stdout.print ">> "
        end

        def receive_line(text)
          exit 0 if text.strip == 'exit'

          message = Qbot::Message.new(text)
          message.text = text
          message.mention(/^\s*bot\b/)

          @callback.call(message)
          $stdout.print ">> "
        end
      end

      def listen(&block)
        EM.run { EM.open_keyboard(Keyboard, block) }
      end

      def close
        EM.stop
      end

      def post(text, **options)
        $stdout.puts text
      end

      def reply_to(message, text, **options)
        post(text, **options)
      end

    end

  end

end
