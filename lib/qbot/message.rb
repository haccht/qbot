module Qbot

  class Message

    attr_accessor :text
    attr_reader :data, :captures

    def initialize(data, text = '')
      @data = data
      @text = text
    end

    def match(regexp, prefix: nil)
      text = @text.dup
      text.sub!(/^#{prefix}/, '') if prefix
      @captures = text.strip.match(regexp)
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
