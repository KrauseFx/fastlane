module Fastlane
  module Actions
    class GooglePlayTrackRolloutPercentagesAction < Action
      # Define options that are applicable for this action.
      OPTIONS = [
        :package_name,
        :track,
        :key,
        :issuer,
        :json_key,
        :json_key_data,
        :root_url,
        :timeout
      ]

      def self.run(params)
        require 'supply'
        require 'supply/options'
        require 'supply/reader'

        Supply.config = params

        rollout_percentages = Supply::Reader.new.track_rollout_percentages || []
        rollout_percentages
      end

      #####################################################
      # @!group Documentation
      #####################################################

      def self.description
        "Retrieves rollout percentages for each release in a Google Play track"
      end

      def self.details
        "More information: [https://docs.fastlane.tools/actions/supply/](https://docs.fastlane.tools/actions/supply/)"
      end

      def self.available_options
        require 'supply'
        require 'supply/options'

        Supply::Options.available_options.select do |option|
          OPTIONS.include?(option.key)
        end
      end

      def self.output
        [
          ['GOOGLE_PLAY_TRACK_ROLLOUT_PERCENTAGES', 'A hash containing the rollout percentages of releases']
        ]
      end

      def self.return_value
        "Hash with release names as keys and rollout percentages as values"
      end

      def self.authors
        ["brainbicycle"]
      end

      def self.is_supported?(platform)
        platform == :android
      end

      def self.example_code
        [
          'google_play_track_rollout_percentages(track: "beta")'
        ]
      end

      def self.category
        :misc
      end
    end
  end
end
