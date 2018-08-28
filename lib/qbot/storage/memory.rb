module Qbot

  class MemoryStorage < Storage

    def initialize
      @db = Hash.new { |h, k| h[k] = {} }
    end

    def namespace(namespace)
      @db[namespace]
    end

  end

end

