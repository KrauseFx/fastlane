module Fastlane
  module Actions
    class RocketAction < Action
      def self.run(params)
        puts("
        ____
       /    \\
      |      |
      |      |
      |      |
       \\____/
       |    |
       |    |
       |    |
       |____|
      {|    |}
       |    |
       |    |
       | F  |
       | A  |
       | S  |
       | T  |
       | L  |
       | A  |
      /| N  |\\
      || E  ||
      ||    ||
      \\|____|/
       /_\\/_\\
       ######
      ########
       ######
        ####
        ####
         ##
         ##
         ##
         ##
         ")
        return "🚀"
      end

      #####################################################
      # @!group Documentation
      #####################################################

      def self.description
        "Outputs ascii-art for a rocket 🚀"
      end

      def self.details
        "Print an ascii Rocket :rocket:. Useful after using _crashlytics_ or _pilot_ to indicate that your new build has been shipped to outer-space."
      end

      def self.available_options
        []
      end

      def self.authors
        ["JaviSoto", "radex"]
      end

      def self.is_supported?(platform)
        true
      end

      def self.example_code
        [
          'rocket'
        ]
      end

      def self.return_type
        :string
      end

      def self.category
        :misc
      end
    end
  end
end
