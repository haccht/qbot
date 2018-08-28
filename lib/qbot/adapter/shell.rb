require 'eventmachine'

module Qbot

  class ShellAdapter < Qbot::Adapter

    module Keyboard

      include EM::Protocols::LineText2

      def initialize(callback)
        @callback = callback
        $stdout.print ">> "
      end

      def receive_line(message)
        exit 0 if message.strip == 'exit'

        @callback.call(message)
        $stdout.print ">> "
      end
    end

    def on_message(&block)
      EM.run { EM.open_keyboard(Keyboard, block) }
    end

    def post(message, **opts)
      $stdout.puts message
    end

  end

end
