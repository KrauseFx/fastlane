module Spaceship
  class Client
    class UserInterface
      # Shows the UI to select a team
      # @example teams value:
      #  [{"status"=>"active",
      #   "teamId"=>"5A997XAAAA",
      #   "type"=>"Company/Organization",
      #   "extendedTeamAttributes"=>{},
      #   "teamAgent"=>{
      #       "personId"=>15534241111,
      #       "firstName"=>"Felix",
      #       "lastName"=>"Krause",
      #       "email"=>"spaceship@krausefx.com",
      #       "developerStatus"=>"active",
      #       "teamMemberId"=>"5Y354CXAAA"},
      #   "memberships"=>
      #    [{"membershipId"=>"HJ5WHYC5CE",
      #      "membershipProductId"=>"ds1",
      #      "status"=>"active",
      #      "inDeviceResetWindow"=>false,
      #      "inRenewalWindow"=>false,
      #      "dateStart"=>"11/20/14 07:59",
      #      "dateExpire"=>"11/20/15 07:59",
      #      "platform"=>"ios",
      #      "availableDeviceSlots"=>100,
      #      "name"=>"iOS Developer Program"}],
      #   "currentTeamMember"=>
      #    {"personId"=>nil, "firstName"=>nil, "lastName"=>nil, "email"=>nil, "developerStatus"=>nil, "privileges"=>{}, "roles"=>["TEAM_ADMIN"], "teamMemberId"=>"HQR8N4GAAA"},
      #   "name"=>"Company GmbH"},
      #     {...}
      #   ]

      # rubocop:disable Require/MissingRequireStatement
      def self.ci?
        if Object.const_defined?("FastlaneCore") && FastlaneCore.const_defined?("Helper")
          return FastlaneCore::Helper.ci?
        end
        return false
      end

      def self.interactive?
        if Object.const_defined?("FastlaneCore") && FastlaneCore.const_defined?("UI")
          return FastlaneCore::UI.interactive?
        end
        return true
      end
      # rubocop:enable Require/MissingRequireStatement

      def select_team(team_id: nil, team_name: nil)
        teams = client.teams

        if teams.count == 0
          puts("No teams available on the Developer Portal")
          puts("You must accept an invitation to a team for it to be available")
          puts("To learn more about teams and how to use them visit https://developer.apple.com/library/ios/documentation/IDEs/Conceptual/AppDistributionGuide/ManagingYourTeam/ManagingYourTeam.html")
          raise "Your account is in no teams"
        end

        team_id = (team_id || ENV['FASTLANE_TEAM_ID'] || '').strip

        # A valid team name may contain leading or trailing spaces
        # See: https://github.com/fastlane/fastlane/pull/21656
        team_name = (team_name || ENV['FASTLANE_TEAM_NAME'] || '')

        if team_id.length > 0
          # User provided a value, let's see if it's valid
          teams.each_with_index do |team, i|
            # There are 2 different values - one from the login page one from the Dev Team Page
            return team['teamId'] if team['teamId'].strip == team_id
            return team['teamId'] if team['currentTeamMember']['teamMemberId'].to_s.strip == team_id
          end
          # Better message to inform user of misconfiguration as Apple now provides less friendly error as of 2019-02-12
          # This is especially important as Developer Portal team IDs are deprecated and should be replaced with App Store Connect teamIDs
          # "Access Unavailable - You currently don't have access to this membership resource. Contact your team's Account Holder, Josh Holtz, or an Admin."
          # https://github.com/fastlane/fastlane/issues/14228
          puts("Couldn't find team with ID '#{team_id}'. Make sure your are using the correct App Store Connect team ID and have the proper permissions for this team")
        end

        if team_name.strip.length > 0
          # User provided a value, let's see if it's valid
          teams.each_with_index do |team, i|
            return team['teamId'] if team['name'].strip == team_name.strip
          end
          # Better message to inform user of misconfiguration as Apple now provides less friendly error as of 2019-02-12
          # "Access Unavailable - You currently don't have access to this membership resource. Contact your team's Account Holder, Josh Holtz, or an Admin."
          # https://github.com/fastlane/fastlane/issues/14228
          puts("Couldn't find team with Name '#{team_name}. Make sure you have the proper permissions for this team'")
        end

        return teams[0]['teamId'] if teams.count == 1 # user is just in one team

        unless self.class.interactive?
          puts("Multiple teams found on the Developer Portal, Your Terminal is running in non-interactive mode! Cannot continue from here.")
          puts("Please check that you set FASTLANE_TEAM_ID or FASTLANE_TEAM_NAME to the right value.")
          puts("Available Teams:")
          teams.each_with_index do |team, i|
            puts("#{i + 1}) #{team['teamId']} \"#{team['name']}\" (#{team['type']})")
          end
          raise "Multiple Teams found; unable to choose, terminal not interactive!"
        end

        # User Selection
        loop do
          # Multiple teams, user has to select
          puts("Multiple teams found on the " + "Developer Portal".yellow + ", please enter the number of the team you want to use: ")
          teams.each_with_index do |team, i|
            puts("#{i + 1}) #{team['teamId']} \"#{team['name']}\" (#{team['type']})")
          end

          selected = ($stdin.gets || '').strip.to_i - 1
          team_to_use = teams[selected] if selected >= 0

          return team_to_use['teamId'] if team_to_use
        end
      end
    end
  end
end
