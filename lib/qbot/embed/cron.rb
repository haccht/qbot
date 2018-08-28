require 'timers'
require 'parse-cron'

class Cron < Qbot::Base

  on /^cron add (\S+ \S+ \S+ \S+ \S+) (.+)$/ do |msg|
    start(unique_id, msg[1], msg[2])
  end

  on /^cron del (\d+)/ do |msg|
    stop(msg[1].to_i)
  end

  on /^cron list\b/ do |msg|
    list
  end

  usage <<~EOL
  Usage:
    `cron add <cron-syntax> <message>` - add a cron scheduler.
    `cron del <cron-id>` - delete the cron schduler.
    `cron list` - list all cron schedulers.
  EOL


  class << self

    def timers
      @timers ||= {}
    end

  end

  def start(id, cron, text)
    begin
      recursive(id, cron, text)
    rescue ArgumentError
      return
    end

    cache[id] = [cron, text]
    post("ADD " + line(id, cron, text))
  end

  def stop(id)
    Cron.timers[id].cancel if Cron.timers[id]
    return unless cache[id]

    cron, text = cache[id]
    cache[id]  = nil
    post("DEL " + line(id, cron, text))
  end

  def list
    resp = StringIO.new
    cache.each do |id, (cron, text)|
      next unless cron && text
      resp.puts line(id, cron, text)
    end

    post(resp.string)
  end

  private
  def recursive(id, cron, text)
    parser  = CronParser.new(cron)
    current = Time.now
    delay   = parser.next(current) - current

    Cron.timers[id] = Qbot.app.timers.after(delay) do
      post(text)
      recursive(id, cron, text)
    end
  end

  def line(id, cron, text)
    "#{id.to_s.rjust(3)}: #{cron} #{text}"
  end

  def unique_id
    loop do
      id = (0..999).to_a.sample
      return id unless cache[id]
    end
  end

end
