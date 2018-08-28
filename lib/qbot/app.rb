require 'singleton'
require 'timers'

module Qbot

  def self.app
    Qbot::Application.instance
  end

  class Application

    include Singleton
    attr_reader :bots
    attr_reader :timers

    def initialize
      @bots   = []
      @timers = Timers::Group.new
    end

    def run(*args)
      th1 = Thread.start { loop { @timers.wait } }
      th2 = Thread.start { adapter.run(bots) }

      [th1, th2].each { |th| th.join }
    end

    def adapter
      @adapter ||= Qbot::Adapter.build
    end

    def storage
      @storage ||= Qbot::Storage.build
    end

  end

end
