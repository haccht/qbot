require 'faraday'
require 'faraday_middleware'
require 'faye/websocket'
require 'json'

module Qbot

  module Adapter

    class Slack < Qbot::Adapter::Driver

      SLACK_API_URL = 'https://slack.com/api'

      def initialize(api_token: nil)
        access_token(api_token || ENV['QBOT_SLACK_API_TOKEN'])
        @server = URI.join(SLACK_API_URL, '/').to_s
        @bot_id = me['user_id']
      end

      def access_token(token)
        @token = token
      end

      def listen(&block)
        EM.run { start_connection(&block) }
      end

      def close
        EM.stop
      end

      def post(text, **options)
        resp = api_call(:post, "/chat.postMessage", options.merge(text: text))
        Qbot.app.logger.info("#{self.class} - Post message: #{resp.status} - '#{text}'")
      end

      def reply_to(message, text, **options)
        if options[:channel_id]
          channel_id = options[:channel_id]
        elsif options[:channel_name]
          channel = channel(options[:channel_name])
          channel_id = channel['id'] if channel
        end

        channel_id ||= message.data['channel'] if message
        return unless channel_id

        post(text, **options.merge(channel: channel_id))
      end

      private
      def endpoint(path)
        URI(SLACK_API_URL).path + path
      end

      def start_connection(&block)
        resp = api_call(:get, '/rtm.start')
        data = JSON.parse(resp.body)

        running = true
        ws_url  = data['url']
        ws = Faye::WebSocket::Client.new(ws_url, nil, {ping: 60})

        ws.on :message do |e|
          data = JSON.parse(e.data)
          emit_event(data, block)
        end

        ws.on :open do |e|
          Qbot.app.logger.info("#{self.class} - Websocket connection opened")
        end

        ws.on :close do |e|
          Qbot.app.logger.info("#{self.class} - Websocket connection closed: #{e.code} #{e.reason}")
          if running
            sleep 3
            start_connection(&block)
          else
            Qbot.app.stop
          end
        end

        ws.on :error do |e|
          Qbot.app.logger.error("#{self.class} - Websocket encountered error: #{e.message}")
          running = false
        end
      end

      def emit_event(data, callback)
        return unless type = data['event']
        Qbot.app.logger.debug("#{self.class} - Event '#{type}' recieved")

        case type
        when 'message'
          return if data['subtype']

          message = Qbot::Message.new(data)
          message.text = data['text']
          message.mention(/^\s*<@#{@bot_id}>/)

          callback.call(message)
        end
      end

      def api_call(method, path, **options, &block)
        connection = Faraday::Connection.new(url: @server ) do |con|
          con.request :url_encoded
          con.adapter :httpclient
        end

        connection.send(
          method,
          endpoint(path),
          { token: @token }.merge(options)
        )
      end

      def me
        resp = api_call(:get, "/auth.test")
        JSON.parse(resp.body)
      end

      def channel(name)
        resp = api_call(:get, "/channels.list")
        data = JSON.parse(resp.body)
        data['channels'].find { |c| c['name'] == name }
      end

    end

  end

end
