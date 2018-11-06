module Qbot

  class Cron < Qbot::Base

    help "cron add <pattern> <message>" => "Add a cron task."
    on /^cron add (\S+ \S+ \S+ \S+ \S+) (.+)$/ do |msg|
      post start(unique_id, msg.captures[1], msg.captures[2])
    end

    help "cron del <cron-id>" => "Remove a cron task."
    on /^cron del (\d+)/ do |msg|
      post stop(msg.captures[1].to_i)
    end

    help "cron list" => "List all cron tasks."
    on /^cron list\b/ do |msg|
      post list_all
    end

    private
    def self.timers
      @timers ||= {}
    end

    def start(id, cron, text)
      schedule(id, cron, text) rescue return

      cache[id] = [cron, text]
      "ADD #{format(id, cron, text)}"
    end

    def stop(id)
      Cron.timers[id].cancel if Cron.timers[id]
      cron, text = cache[id]

      cache[id] = nil
      "DEL #{format(id, cron, text)}"
    end

    def list_all
      resp = StringIO.new
      cache.each do |id, (cron, text)|
        next unless cron && text
        resp.puts format(id, cron, text)
      end

      resp.string.chomp
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

    def format(id, cron, text)
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
