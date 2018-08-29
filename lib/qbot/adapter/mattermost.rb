require 'json'
require 'mattermost'

module Qbot

  module Adapter

    class Mattermost < Qbot::Adapter::Driver

      def initialize
        server   = ENV['QBOT_MATTERMOST_URI']
        username = ENV['QBOT_MATTERMOST_USERNAME']
        password = ENV['QBOT_MATTERMOST_PASSWORD']
        raise "#{self.class}: Argument Error" unless server && username && password

        @client = ::Mattermost::Client.new(server)
        @client.login(username, password)

        @client.connected?
        @client.connect_websocket.connected?
      end

      def on_message(&block)
        @client.ws_client.on :message do |json|
          data = JSON.load(data)

          message = Qbot::Message.new
          message.data = data
          message.text = data['message']

          block.call(message)
        end
      end

      def post(text, **opts)
        channel_id = opts[:channel_id] || channel_id(opts[:channel])
        @client.create_post({message: text, channel_id: channel_id})
      end

      private
      def channel_id(name)
        resp = @client.get_channel_by_name(team_id, name)
        resp.body['id']
      end

      def team_id
        if name = ENV['QBOT_MATTERMOST_TEAM']
          resp = @client.get_team_by_name(name)
          resp.body['id']
        else
          resp = @client.get_teams_for_user(ENV['QBOT_MATTERMOST_USERNAME'])
          resp.body[0]['id']
        end
      end

    end

  end

end
