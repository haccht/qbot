require 'leveldb'

module Qbot

  module Storage

    class LevelDB < Qbot::Storage::Driver

      QBOT_LEVELDB_DEFAULT_DATABASE = 'qbot-storage.db'
      QBOT_LEVELDB_DEFAULT_BACKUP_INTERVAL = 5

      def initialize
        interval = ENV['QBOT_LEVELDB_BACKUP_INTERVAL'] || QBOT_LEVELDB_DEFAULT_BACKUP_INTERVAL
        database = ENV['QBOT_LEVELDB_DATABASE']        || QBOT_LEVELDB_DEFAULT_DATABASE

        @db = ::LevelDB::DB.new(File.join(Dir.pwd, database))
        @cache = {}

        restore
        Qbot.app.timers.every(interval) { backup }
      end

      def namespace(ns)
        @cache[ns] ||= {}
      end

      private
      def backup
        return if @cache.keys.empty?
        @db.batch do |batch|
          @cache.each { |ns, v| batch[ns] = Marshal.dump(v) }
        end
      end

      def restore
        return if @db.keys.empty?
        @db.each { |ns, v| @cache[ns] = Marshal.load(v) }
      end

    end

  end

end
