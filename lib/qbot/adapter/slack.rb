require 'faraday'
require 'faraday_middleware'
require 'faye/websocket'
require 'json'

module Qbot

  module Adapter

    class Slack < Qbot::Adapter::Driver

      SLACK_API_URL = 'https://slack.com/api'

      def initialize(api_token: nil)
        @server = URI.join(SLACK_API_URL, '/').to_s
        @error  = false

        access_token(api_token || ENV['QBOT_SLACK_API_TOKEN'])
      end

      def access_token(token)
        @token = token
      end

      def on_message(&block)
        resp = api_call(:get, '/rtm.start')
        data = JSON.parse(resp.body)
        ws_url = data['url']

        EM.run do
          @ws = Faye::WebSocket::Client.new(ws_url, {}, { ping: 60})

          @ws.on :open do |e|
            Qbot.app.logger.info("#{self.class} - Websocket connection opened")
          end

          @ws.on :close do |e|
            Qbot.app.logger.info("#{self.class} - Websocket connection closed")
            stop if @error
            on_message(&block) # restart
          end

          @ws.on :error do |e|
            Qbot.app.logger.error("#{self.class} - #{e.message}")
            @error = true
          end

          @ws.on :message do |e|
            data = JSON.parse(e.data)
            emit_event(data, block)
          end
        end
      end

      def stop
        EM.stop
      end

      def post(text, **options)
        api_call(:post, "/chat.postMessage", options.merge(text: text))
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

      def emit_event(data, callback)
        event = data['type'].to_sym
        Qbot.app.logger.debug("#{self.class} - Event '#{event}' recieved")

        case event
        when :message
          return if data['subtype']

          message = Qbot::Message.new
          message.data = data
          message.text = data['text']

          Qbot.app.logger.info("#{self.class} - Message was '#{message.text}'")
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
