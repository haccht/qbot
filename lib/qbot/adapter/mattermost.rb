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
        seq = 0
        ws_url = URI.join(@server.gsub(/^http(s?):/, 'ws\1:'), endpoint('/websocket')).to_s
        headers = { "Authorization" => "Bearer #{@token}" }

        EM.run do
          @ws = Faye::WebSocket::Client.new(ws_url, {}, { headers: headers, ping: 60})

          @ws.on :open do |e|
            $stderr.puts 'ws open'
          end

          @ws.on :close do |e|
            $stderr.puts "ws close: #{e.reason}"
          end

          @ws.on :error do |e|
            $stderr.puts "ws error: #{e.message}"
          end

          @ws.on :message do |e|
            data = JSON.parse(e.data)
            seq = data["seq"] if data["seq"] && seq < data["seq"]

            $stderr.puts "recieved #{data['event']}"
            case event = data['event'].to_sym
            when :posted
              post = JSON.parse(data['data']['post'])
              $stderr.puts "recieved message: #{post['message']}"

              message = Qbot::Message.new
              message.data = post
              message.text = post['message']

              block.call(message)
            end
          end
        end
      end

      def stop
        EM.stop
      end

      def post(text, **opts)
        request(:post, "/posts", :body => {
          message:    text,
          channel_id: opts[:channel_id] || channel(opts[:channel])['id'],
        })
      end

      private
      def endpoint(path)
        URI(@mm_url).path + "/api/v4#{path}"
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
