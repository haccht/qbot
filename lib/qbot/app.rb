require 'singleton'
require 'timers'

require 'qbot/version'

module Qbot

  class << self

    def app
      Qbot::Application.instance
    end

    def run!(*args)
      app.start
    end

  end

  class Application

    include Singleton
    attr_reader :timers

    def initialize
      @bots    = []
      @threads = []
      @timers  = Timers::Group.new
    end

    def add(bot)
      @bots << bot
    end

    def bots
      @bots.map { |bot| bot.class.name }.uniq
    end

    def start
      @threads << Thread.start { loop { @timers.wait } }
      @threads << Thread.start { adapter.run(@bots) }
      @threads.each { |th| th.join }
    end

    def stop
      @threads.each { |th| th.kill }
    end

    def adapter
      @adapter ||= Qbot::Adapter::Driver.build
    end

    def storage
      @storage ||= Qbot::Storage::Driver.build
    end

  end

end
