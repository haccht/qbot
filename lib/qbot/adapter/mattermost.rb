require 'faraday'
require 'faraday_middleware'
require 'faye/websocket'
require 'json'

module Qbot

  module Adapter

    class Mattermost < Qbot::Adapter::Driver

      def initialize(url: nil, username: nil, password: nil)
        @mm_url  = url || ENV['QBOT_MATTERMOST_URL']
        @server  = URI.join(@mm_url, '/').to_s
        @token   = nil
        @error   = false

        resp = request(:post, '/users/login', :body => {
          login_id: username || ENV['QBOT_MATTERMOST_USERNAME'],
          password: password || ENV['QBOT_MATTERMOST_PASSWORD'],
        })

        access_token(resp.headers['token'])
      end

      def access_token(token)
        @token = token
      end

      def on_message(&block)
        ws_url = URI.join(@server.gsub(/^http(s?):/, 'ws\1:'), endpoint('/websocket')).to_s
        headers = { "Authorization" => "Bearer #{@token}" }

        EM.run do
          @ws = Faye::WebSocket::Client.new(ws_url, {}, { headers: headers, ping: 60})

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

      def reply_to(message, text, **options)
        channel_id = options[:channel_id]
        channel_id ||= channel(options[:channel])['id'] if options[:channel]
        channel_id ||= message.data['channel_id']
        return unless channel_id

        request(:post, "/posts", :body => {
          message:    text,
          channel_id: channel_id
        })
      end

      private
      def endpoint(path)
        URI(@mm_url).path + "/api/v4#{path}"
      end

      def emit_event(data, callback)
        event = data['event'].to_sym
        Qbot.app.logger.debug("#{self.class} - Event '#{event}' recieved")

        case event
        when :posted
          post = JSON.parse(data['data']['post'])

          message = Qbot::Message.new
          message.data = post
          message.text = post['message']

          Qbot.app.logger.info("#{self.class} - Message was '#{post['message']}'")
          callback.call(message)
        end
      end

      def request(method, path, **options, &block)
        headers = { "Authorization" => "Bearer #{@token}", "Accept" => "application/json" }
        connection = Faraday::Connection.new(url: @server, headers: headers ) do |con|
          con.response :json
          con.adapter  :httpclient
        end

        connection.send(method) do |request|
          request.url endpoint(path), options
          request.body = options[:body].to_json if options[:body]
        end
      end

      def me
        request(:get, "/users/me")
      end

      def channel(name)
        resp = request(:get, "/teams/#{team['id']}/channels/name/#{name}")
        resp.body
      end

      def team
        if name = ENV['QBOT_MATTERMOST_TEAM']
          resp = request(:get, "/teams/name/#{name}")
          resp.body
        else
          resp = request(:get, "/users/#{me['id']}/teams")
          resp.body.first
        end
      end

    end

  end

end
