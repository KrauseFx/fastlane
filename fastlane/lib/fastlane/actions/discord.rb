module Fastlane
  module Actions
    class DiscordAction < Action
      def self.run(params)
        # UI.message "Target: #{params[:discord_url]}"
        # UI.message "Content: #{params[:content]}"

        @client = Faraday.new do |conn|
          conn.use(Faraday::Response::RaiseError)
        end

        @client.post(params[:discord_url]) do |request|
          request.headers['Content-Type'] = 'application/json'
          request.body = {
            content: params[:content],
          }.to_json
        end
        UI.success('Successfully sent Discord notification')
      end

      #####################################################
      # @!group Documentation
      #####################################################

      def self.description
        "Send message to a Discord webhook"
      end

      def self.details
        "Create an Incoming WebHook and copy the webhook url to pass in 'discord(content, discord_url);'"
      end

      def self.category
        :notifications
      end

      def self.available_options
        [
          FastlaneCore::ConfigItem.new(key: :discord_url,
            env_name: "DISCORD_URL",
            description: "Discord webhook URL", # POST target URL
            verify_block: proc do |value|
              UI.user_error!("No discord_url, pass with `discord_url: 'webhook url'`") unless value && (!value.empty?)
            end),
          FastlaneCore::ConfigItem.new(key: :content,
            description: "content", # message text
            verify_block: proc do |value|
              UI.user_error!("No message, pass using `content: 'message here'`") unless value && (!value.empty?)
            end)
        ]
      end

      def self.is_supported?(platform)
        true
      end

      def self.authors
        ["arnotixe"]
        # mostly ripped off Krausefx's slack action
      end
    end
  end
end
