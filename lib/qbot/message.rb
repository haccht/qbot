
module Qbot

  class Message

    attr_accessor :data, :text

    def initialize(data, text = nil)
      @data = data
      @text = text
    end

    def mention(regexp = nil)
      @mention = text.slice(regexp) if regexp
      @mention
    end

    def mentioned?
      !!mention
    end
  end

end
