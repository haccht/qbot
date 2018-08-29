module Qbot

  module Storage

    class Driver

      class << self

        def inherited(subclass)
          @target = subclass
        end

        def build
          @target.new
        end

      end

      def namespace(ns)
        raise 'Not implemented'
      end

    end

  end

end
