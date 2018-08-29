require 'leveldb'

module Qbot

  module Storage

    class LevelDB < Qbot::Storage::Driver

      QBOT_LEVELDB_DEFAULT_DATABASE = 'qbot.db'
      QBOT_LEVELDB_DEFAULT_BACKUP_INTERVAL = 5

      def initialize
        interval = ENV['QBOT_LEVELDB_BACKUP_INTERVAL'] || QBOT_LEVELDB_DEFAULT_BACKUP_INTERVAL
        database = ENV['QBOT_LEVELDB_DATABASE']        || QBOT_LEVELDB_DEFAULT_DATABASE

        @db = ::LevelDB::DB.new(File.join(Dir.pwd, database))
        @cache = restore || {}

        Qbot.app.timers.every(interval) { backup }
      end

      def namespace(ns)
        @cache[ns] ||= {}
      end

      private
      def backup
        entrypoint = Marshal.dump(@cache)
      end

      def restore
        @Marshal.load(entrypoint) if entrypoint
      end

      def entrypoint
        @db[self.class.name.to_s]
      end

    end

  end

end
