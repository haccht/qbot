require 'singleton'
require 'timers'

require 'qbot/version'

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
      [
        Thread.start { loop { @timers.wait } },
        Thread.start { adapter.run(bots) },
      ].each { |th| th.join }
    end

    def adapter
      @adapter ||= Qbot::Adapter.build
    end

    def storage
      @storage ||= Qbot::Storage.build
    end

  end

end
