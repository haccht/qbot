require 'logger'
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
    attr_reader :logger

    def initialize
      @bots    = []
      @threads = []
      @timers  = Timers::Group.new
      @logger  = Logger.new(STDOUT)
    end

    def add(bot)
      @bots << bot
    end

    def bots
      @bots.map { |bot| bot.class.name }.uniq
    end

    def start
      @logger.info("Booting #{self.class}.")
      @logger.info("#{storage.class} - Storage driver loaded")
      @logger.info("#{adapter.class} - Adapter driver loaded")

      @threads << Thread.start { loop { @timers.wait } }
      @threads << Thread.start { adapter.run(@bots) }
      @threads.each { |th| th.join }
    end

    def stop
      adapter.stop if adapter.respond_to?(:stop)
      @threads.each { |th| th.kill if th }
    end

    def adapter
      @adapter ||= Qbot::Adapter::Driver.build
    end

    def storage
      @storage ||= Qbot::Storage::Driver.build
    end

  end

end
