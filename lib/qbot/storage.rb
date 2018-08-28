module Qbot

  class Storage

    class << self

      def inherited(subclass)
        @target = subclass
      end

      def build
        @target.new
      end

    end

    def namespace(namespace)
      raise 'Not implemented'
    end

  end

end
