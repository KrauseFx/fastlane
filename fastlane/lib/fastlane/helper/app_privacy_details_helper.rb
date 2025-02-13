module Fastlane
  module Helper
    class AppPrivacyDetailsHelper
      def self.usages_config_from_raw_usages(raw_usages:)
        usages_config = []
        if raw_usages.count == 1 && raw_usages.first.data_protection.id == Spaceship::ConnectAPI::AppDataUsageDataProtection::ID::DATA_NOT_COLLECTED
          usages_config << {
            "data_protections" => [Spaceship::ConnectAPI::AppDataUsageDataProtection::ID::DATA_NOT_COLLECTED]
          }
        else
          grouped_usages = raw_usages.group_by do |usage|
            usage.category.id
          end
          grouped_usages.sort_by(&:first).each do |key, usage_group|
            purposes = usage_group.map(&:purpose).compact || []
            data_protections = usage_group.map(&:data_protection).compact || []
            usages_config << {
              "category" => key,
              "purposes" => purposes.map(&:id).sort.uniq,
              "data_protections" => data_protections.map(&:id).sort.uniq
            }
          end
        end
        usages_config
      end
    end
  end
end
