require 'fastlane/notification/slack'

# rubocop:disable Style/CaseEquality
# rubocop:disable Style/MultilineTernaryOperator
# rubocop:disable Style/NestedTernaryOperator
module Fastlane
  module Actions
    class SlackAction < Action
      class Runner
        def initialize(slack_url)
          @notifier = Fastlane::Notification::Slack.new(slack_url)
        end

        def run(options)
          options[:message] = self.class.trim_message(options[:message].to_s || '')
          options[:message] = Fastlane::Notification::Slack::LinkConverter.convert(options[:message])

          options[:pretext] = options[:pretext].gsub('\n', "\n") unless options[:pretext].nil?

          if options[:channel].to_s.length > 0
            channel = options[:channel]
            channel = ('#' + options[:channel]) unless ['#', '@'].include?(channel[0]) # send message to channel by default
            (channel[0] = '') if channel[0] == '@'
          end

          username = options[:use_webhook_configured_username_and_icon] ? nil : options[:username]

          slack_attachment = self.class.generate_slack_attachments(options)
          link_names = options[:link_names]
          icon_url = options[:use_webhook_configured_username_and_icon] ? nil : options[:icon_url]
          icon_emoji = options[:use_webhook_configured_username_and_icon] ? nil : options[:icon_emoji]

          post_message(
            channel: channel,
            username: username,
            attachments: [slack_attachment],
            link_names: link_names,
            icon_url: icon_url,
            icon_emoji: icon_emoji,
            fail_on_error: options[:fail_on_error]
          )
        end

        def post_message(channel:, username:, attachments:, link_names:, icon_url:, icon_emoji:, fail_on_error:)
          @notifier.post_to_legacy_incoming_webhook(
            channel: channel,
            username: username,
            link_names: link_names,
            icon_url: icon_url,
            icon_emoji: icon_emoji,
            attachments: attachments
          )
          UI.success('Successfully sent Slack notification')
        rescue => error
          UI.error("Exception: #{error}")
          message = "Error pushing Slack message, maybe the integration has no permission to post on this channel? Try removing the channel parameter in your Fastfile, this is usually caused by a misspelled or changed group/channel name or an expired SLACK_URL"
          if fail_on_error
            UI.user_error!(message)
          else
            UI.error(message)
          end
        end

        # As there is a text limit in the notifications, we are
        # usually interested in the last part of the message
        # e.g. for tests
        def self.trim_message(message)
          # We want the last 7000 characters, instead of the first 7000, as the error is at the bottom
          start_index = [message.length - 7000, 0].max
          message = message[start_index..-1]
          # We want line breaks to be shown on slack output so we replace
          # input non-interpreted line break with interpreted line break
          message.gsub('\n', "\n")
        end

        def self.generate_slack_attachments(options)
          color = (options[:success] ? 'good' : 'danger')
          should_add_payload = ->(payload_name) { options[:default_payloads].map(&:to_sym).include?(payload_name.to_sym) }

          slack_attachment = {
            fallback: options[:message],
            text: options[:message],
            pretext: options[:pretext],
            color: color,
            mrkdwn_in: ["pretext", "text", "fields", "message"],
            fields: []
          }

          # custom user payloads
          slack_attachment[:fields] += options[:payload].map do |k, v|
            {
              title: k.to_s,
              value: Fastlane::Notification::Slack::LinkConverter.convert(v.to_s),
              short: false
            }
          end

          # Add the lane to the Slack message
          # This might be nil, if slack is called as "one-off" action
          if should_add_payload[:lane] && Actions.lane_context[Actions::SharedValues::LANE_NAME]
            slack_attachment[:fields] << {
              title: 'Lane',
              value: Actions.lane_context[Actions::SharedValues::LANE_NAME],
              short: true
            }
          end

          # test_result
          if should_add_payload[:test_result]
            slack_attachment[:fields] << {
              title: 'Result',
              value: (options[:success] ? 'Success' : 'Error'),
              short: true
            }
          end

          # git branch
          if Actions.git_branch && should_add_payload[:git_branch]
            slack_attachment[:fields] << {
              title: 'Git Branch',
              value: Actions.git_branch,
              short: true
            }
          end

          # git_author
          if Actions.git_author_email && should_add_payload[:git_author]
            if FastlaneCore::Env.truthy?('FASTLANE_SLACK_HIDE_AUTHOR_ON_SUCCESS') && options[:success]
            # We only show the git author if the build failed
            else
              slack_attachment[:fields] << {
                title: 'Git Author',
                value: Actions.git_author_email,
                short: true
              }
            end
          end

          # last_git_commit
          if Actions.last_git_commit_message && should_add_payload[:last_git_commit]
            slack_attachment[:fields] << {
              title: 'Git Commit',
              value: Actions.last_git_commit_message,
              short: false
            }
          end

          # last_git_commit_hash
          if Actions.last_git_commit_hash(true) && should_add_payload[:last_git_commit_hash]
            slack_attachment[:fields] << {
              title: 'Git Commit Hash',
              value: Actions.last_git_commit_hash(short: true),
              short: false
            }
          end

          # merge additional properties
          deep_merge(slack_attachment, options[:attachment_properties])
        end

        # Adapted from https://stackoverflow.com/a/30225093/158525
        def self.deep_merge(a, b)
          merger = proc do |key, v1, v2|
            Hash === v1 && Hash === v2 ?
              v1.merge(v2, &merger) : Array === v1 && Array === v2 ?
                                        v1 | v2 : [:undefined, nil, :nil].include?(v2) ? v1 : v2
          end
          a.merge(b, &merger)
        end
      end

      def self.is_supported?(platform)
        true
      end

      def self.run(options)
        Runner.new(options[:slack_url]).run(options)
      end

      def self.description
        "Send a success/error message to your [Slack](https://slack.com) group"
      end

      def self.available_options
        [
          FastlaneCore::ConfigItem.new(key: :message,
                                       env_name: "FL_SLACK_MESSAGE",
                                       description: "The message that should be displayed on Slack. This supports the standard Slack markup language",
                                       optional: true),
          FastlaneCore::ConfigItem.new(key: :pretext,
                                       env_name: "FL_SLACK_PRETEXT",
                                       description: "This is optional text that appears above the message attachment block. This supports the standard Slack markup language",
                                       optional: true),
          FastlaneCore::ConfigItem.new(key: :channel,
                                       env_name: "FL_SLACK_CHANNEL",
                                       description: "#channel or @username",
                                       optional: true),
          FastlaneCore::ConfigItem.new(key: :use_webhook_configured_username_and_icon,
                                       env_name: "FL_SLACK_USE_WEBHOOK_CONFIGURED_USERNAME_AND_ICON",
                                       description: "Use webhook's default username and icon settings? (true/false)",
                                       default_value: false,
                                       type: Boolean,
                                       optional: true),
          FastlaneCore::ConfigItem.new(key: :slack_url,
                                       env_name: "SLACK_URL",
                                       sensitive: true,
                                       description: "Create an Incoming WebHook for your Slack group",
                                       verify_block: proc do |value|
                                         UI.user_error!("Invalid URL, must start with https://") unless value.start_with?("https://")
                                       end),
          FastlaneCore::ConfigItem.new(key: :username,
                                       env_name: "FL_SLACK_USERNAME",
                                       description: "Overrides the webhook's username property if use_webhook_configured_username_and_icon is false",
                                       default_value: "fastlane",
                                       optional: true),
          FastlaneCore::ConfigItem.new(key: :icon_url,
                                       env_name: "FL_SLACK_ICON_URL",
                                       description: "Specifies a URL of an image to use as the photo of the message. Overrides the webhook's image property if use_webhook_configured_username_and_icon is false",
                                       default_value: "https://fastlane.tools/assets/img/fastlane_icon.png",
                                       optional: true),
          FastlaneCore::ConfigItem.new(key: :icon_emoji,
                                       env_name: "FL_SLACK_ICON_EMOJI",
                                       description: "Specifies an emoji (using colon shortcodes, eg. :white_check_mark:) to use as the photo of the message. Overrides the webhook's image property if use_webhook_configured_username_and_icon is false. This parameter takes precedence over icon_url",
                                       optional: true),
          FastlaneCore::ConfigItem.new(key: :payload,
                                       env_name: "FL_SLACK_PAYLOAD",
                                       description: "Add additional information to this post. payload must be a hash containing any key with any value",
                                       default_value: {},
                                       type: Hash),
          FastlaneCore::ConfigItem.new(key: :default_payloads,
                                       env_name: "FL_SLACK_DEFAULT_PAYLOADS",
                                       description: "Specifies default payloads to include. Pass an empty array to suppress all the default payloads",
                                       default_value: ['lane', 'test_result', 'git_branch', 'git_author', 'last_git_commit', 'last_git_commit_hash'],
                                       type: Array),
          FastlaneCore::ConfigItem.new(key: :attachment_properties,
                                       env_name: "FL_SLACK_ATTACHMENT_PROPERTIES",
                                       description: "Merge additional properties in the slack attachment, see https://api.slack.com/docs/attachments",
                                       default_value: {},
                                       type: Hash),
          FastlaneCore::ConfigItem.new(key: :success,
                                       env_name: "FL_SLACK_SUCCESS",
                                       description: "Was this build successful? (true/false)",
                                       optional: true,
                                       default_value: true,
                                       type: Boolean),
          FastlaneCore::ConfigItem.new(key: :fail_on_error,
                                       env_name: "FL_SLACK_FAIL_ON_ERROR",
                                       description: "Should an error sending the slack notification cause a failure? (true/false)",
                                       optional: true,
                                       default_value: true,
                                       type: Boolean),
          FastlaneCore::ConfigItem.new(key: :link_names,
                                       env_name: "FL_SLACK_LINK_NAMES",
                                       description: "Find and link channel names and usernames (true/false)",
                                       optional: true,
                                       default_value: false,
                                       type: Boolean)
        ]
      end

      def self.author
        "KrauseFx"
      end

      def self.example_code
        [
          'slack(message: "App successfully released!")',
          'slack(
            message: "App successfully released!",
            channel: "#channel",  # Optional, by default will post to the default channel configured for the POST URL.
            success: true,        # Optional, defaults to true.
            payload: {            # Optional, lets you specify any number of your own Slack attachments.
              "Build Date" => Time.new.to_s,
              "Built by" => "Jenkins",
            },
            default_payloads: [:git_branch, :git_author], # Optional, lets you specify default payloads to include. Pass an empty array to suppress all the default payloads.
            attachment_properties: { # Optional, lets you specify any other properties available for attachments in the slack API (see https://api.slack.com/docs/attachments).
                                     # This hash is deep merged with the existing properties set using the other properties above. This allows your own fields properties to be appended to the existing fields that were created using the `payload` property for instance.
              thumb_url: "http://example.com/path/to/thumb.png",
              fields: [{
                title: "My Field",
                value: "My Value",
                short: true
              }]
            }
          )'
        ]
      end

      def self.category
        :notifications
      end

      def self.details
        "Create an Incoming WebHook and export this as `SLACK_URL`. Can send a message to **#channel** (by default), a direct message to **@username** or a message to a private group **group** with success (green) or failure (red) status."
      end

      #####################################################
      # @!group Helper
      #####################################################

      def self.trim_message(message)
        Runner.trim_message(message)
      end

      def self.generate_slack_attachments(options)
        UI.deprecated('`Fastlane::Actions::Slack.generate_slack_attachments` is subject to be removed as Slack recommends migrating `attachments` to Block Kit. fastlane will also follow the same direction.')
        Runner.generate_slack_attachments(options)
      end
    end
  end
end
# rubocop:enable Style/CaseEquality
# rubocop:enable Style/MultilineTernaryOperator
# rubocop:enable Style/NestedTernaryOperator
