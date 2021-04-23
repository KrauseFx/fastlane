module Fastlane
  module Actions
    class NotificationAction < Action
      def self.run(params)
        require 'terminal-notifier'

        options = params.values
        # :message is non-optional
        message = options.delete(:message)
        # remove nil keys, since `notify` below does not ignore them and instead translates them into empty strings in output, which looks ugly
        options = options.select { |_, v| v }
        option_map = {
          app_icon: :appIcon,
          content_image: :contentImage
        }
        options = options.map { |k, v| [option_map.fetch(k, k), v] }.to_h
        TerminalNotifier.notify(message, options)
      end

      def self.description
        "Display a macOS notification with custom message and title"
      end

      def self.author
        ["champo", "cbowns", "KrauseFx", "amarcadet", "dusek"]
      end

      def self.available_options
        [
          FastlaneCore::ConfigItem.new(key: :title,
                                       description: "The title to display in the notification",
                                       default_value: 'fastlane'),
          FastlaneCore::ConfigItem.new(key: :subtitle,
                                       description: "A subtitle to display in the notification",
                                       optional: true),
          FastlaneCore::ConfigItem.new(key: :message,
                                       description: "The message to display in the notification",
                                       optional: false),
          FastlaneCore::ConfigItem.new(key: :sound,
                                       description: "The name of a sound to play when the notification appears (names are listed in Sound Preferences)",
                                       optional: true),
          FastlaneCore::ConfigItem.new(key: :activate,
                                       description: "Bundle identifier of application to be opened when the notification is clicked",
                                       optional: true),
          FastlaneCore::ConfigItem.new(key: :app_icon,
                                       description: "The URL of an image to display instead of the application icon (Mavericks+ only)",
                                       optional: true),
          FastlaneCore::ConfigItem.new(key: :content_image,
                                       description: "The URL of an image to display attached to the notification (Mavericks+ only)",
                                       optional: true),
          FastlaneCore::ConfigItem.new(key: :open,
                                       description: "URL of the resource to be opened when the notification is clicked",
                                       optional: true),
          FastlaneCore::ConfigItem.new(key: :execute,
                                       description: "Shell command to run when the notification is clicked",
                                       optional: true)
        ]
      end

      def self.is_supported?(platform)
        Helper.mac?
      end

      def self.example_code
        [
          'notification(subtitle: "Finished Building", message: "Ready to upload...")'
        ]
      end

      def self.category
        :notifications
      end
    end
  end
end
