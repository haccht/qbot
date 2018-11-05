
module Qbot

  class Message

    attr_reader :data, :mention
    attr_accessor :text

    def initialize(data, text = nil)
      @data = data
      @text = text
    end

    def initialize_copy(obj)
      @data    = obj.data
      @text    = obj.text
      @mention = obj.mention
    end

    def mention(regexp = nil)
      return @mention_proc = lambda { @text.slice!(regexp) } if regexp

      @mention ||= @mention_proc.call if @mention_proc
      @mention
    end

    def mentioned?
      !!mention
    end
  end

end
