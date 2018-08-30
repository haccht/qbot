module Qbot

  class Cron < Qbot::Base

    on /^cron add (\S+ \S+ \S+ \S+ \S+) (.+)$/ do |msg|
      post start(unique_id, msg[1], msg[2])
    end

    on /^cron del (\d+)/ do |msg|
      post stop(msg[1].to_i)
    end

    on /^cron list\b/ do |msg|
      post list_all
    end

    usage <<~EOL
    Usage:
      `cron add <pattern> <message>` - add a cron task.
      `cron del <cron-id>`           - remove a cron task.
      `cron list`                    - list all cron tasks.
    EOL

    def self.timers
      @timers ||= {}
    end

    def start(id, cron, text)
      schedule(id, cron, text) rescue return

      cache[id] = [cron, text]
      "ADD " + dump_line(id, cron, text)
    end

    def stop(id)
      Cron.timers[id].cancel if Cron.timers[id]
      cron, text = cache[id]
      return unless cron && text

      cache[id]  = nil
      "DEL " + dump_line(id, cron, text)
    end

    def list_all
      resp = StringIO.new
      cache.each do |id, (cron, text)|
        next unless cron && text
        resp.puts dump_line(id, cron, text)
      end

      resp.string
    end

    private
    def schedule(id, cron, text)
      parser  = CronParser.new(cron)
      current = Time.now
      delay   = parser.next(current) - current

      Cron.timers[id] = Qbot.app.timers.after(delay) do
        post(text)
        schedule(id, cron, text)
      end
    end

    def dump_line(id, cron, text)
      "#{id.to_s.rjust(3, '0')}: #{cron} #{text}"
    end

    def unique_id
      loop do
        id = (0..999).to_a.sample
        return id unless cache[id]
      end
    end

  end

end
