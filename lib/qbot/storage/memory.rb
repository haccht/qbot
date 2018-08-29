module Qbot

  module Storage

    class Memory < Qbot::Storage::Driver

      def initialize
        @db = Hash.new { |h, k| h[k] = {} }
      end

      def namespace(ns)
        @db[ns]
      end

    end

  end

end
