module Qbot

  module Storage

    class Memory < Qbot::Storage::Driver

      def initialize
        @db = {}
      end

      def namespace(ns)
        @db[ns]
      end

    end

  end

end
