module Fastlane
  module Actions
    class SpaceshipStatsAction < Action
      def self.run(params)
        require 'fastlane_core/print_table'
        require 'spaceship'

        rows = []
        Spaceship::StatsMiddleware.service_stats.each do |service, count|
          rows << [service.name, service.auth_type, service.url, count]
        end

        puts("")
        puts(Terminal::Table.new(
               title: "Spaceship Stats",
               headings: ["Service", "Auth Type", "URL", "Number of requests"],
               rows: FastlaneCore::PrintTable.transform_output(rows)
             ))
        puts("")

        if params[:print_request_logs]
          log_rows = []
          Spaceship::StatsMiddleware.request_logs.each do |request_log|
            log_rows << [request_log.auth_type, request_log.url]
          end

          puts("")
          puts(Terminal::Table.new(
                 title: "Spaceship Request Log",
                 headings: ["Auth Type", "URL"],
                 rows: FastlaneCore::PrintTable.transform_output(log_rows)
               ))
          puts("")
        end
      end

      def self.url_name(url_prefix)
        Spaceship::StatsMiddleware::URL_PREFIXES[url_prefix]
      end

      def self.description
        "Print out Spaceship stats from this session (number of request to each domain)"
      end

      def self.is_supported?(platform)
        true
      end

      def self.available_options
        [
          FastlaneCore::ConfigItem.new(key: :print_request_logs,
                                       description: "Print all URLs requested",
                                       type: Boolean,
                                       default_value: false)
        ]
      end

      def self.example_code
        [
          'spaceship_stats'
        ]
      end

      def self.category
        :misc
      end

      def self.author
        "joshdholtz"
      end
    end
  end
end
