require 'faraday'
require 'faraday_middleware'
require 'faye/websocket'
require 'json'

module Qbot

  module Adapter

    class Mattermost < Qbot::Adapter::Driver

      def initialize(url: nil, username: nil, password: nil)
        @mm_url = url || ENV['QBOT_MATTERMOST_URL']
        @server = URI.join(@mm_url, '/').to_s

        resp = api_call(:post, '/users/login', :body => {
          login_id: username || ENV['QBOT_MATTERMOST_USERNAME'],
          password: password || ENV['QBOT_MATTERMOST_PASSWORD'],
        })

        access_token(resp.headers['token'])
        raise 'Login failed' unless @token

        @bot_id = me['username']
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
        if options[:channel_id]
          # do nothing
        elsif options[:channel_name]
          channel = channel(options.delete(:channel_name))
          options[:channel_id] = channel['id'] if channel
        elsif options[:reply_to]
          message = options.delete(:reply_to)
          options[:channel_id] = message.data['channel_id']
        end

        return unless options[:channel_id]
        Qbot.app.logger.info("#{self.class} - Post message: '#{text}'")
        api_call(:post, "/posts", body: options.merge(message: text))
      end

      private
      def endpoint(path)
        URI(@mm_url).path + "/api/v4#{path}"
      end

      def start_connection(&block)
        running = true
        ws_url  = URI.join(@server.gsub(/^http(s?):/, 'ws\1:'), endpoint('/websocket')).to_s

        ws = Faye::WebSocket::Client.new(ws_url, nil, {ping: 60})
        ws.send({seq: 1, action: 'authentication_challenge', data: {token: @token}}.to_json)

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
        when 'posted'
          data = JSON.parse(data['data']['post'])

          message = Qbot::Message.new(data)
          message.text = data['message']
          message.mention(/^\s*@#{@bot_id}\b/)

          callback.call(message)
        end
      rescue => err
        Qbot.app.logger.error("#{self.class} - ERROR: #{err}")
      end

      def api_call(method, path, **options, &block)
        headers = { "Authorization" => "Bearer #{@token}", "Accept" => "application/json" }
        connection = Faraday::Connection.new(url: @server, headers: headers) do |con|
          con.response :json
          con.adapter  :httpclient
        end

        connection.send(method) do |request|
          request.url endpoint(path), options
          request.body = options[:body].to_json if options[:body]
        end
      end

      def me
        resp = api_call(:get, "/users/me")
        resp.body
      end

      def channel(name)
        resp = api_call(:get, "/teams/#{team['id']}/channels/name/#{name}")
        resp.body
      end

      def team
        if name = ENV['QBOT_MATTERMOST_TEAM']
          resp = api_call(:get, "/teams/name/#{name}")
          resp.body
        else
          resp = api_call(:get, "/users/#{me['id']}/teams")
          resp.body.first
        end
      end

    end

  end

end
