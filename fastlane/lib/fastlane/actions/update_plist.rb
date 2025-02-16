module Fastlane
  module Actions
    module SharedValues
    end

    class UpdatePlistAction < Action
      def self.run(params)
        require 'xcodeproj'

        if params[:plist_path].nil?
          UI.user_error!("You must specify a plist path")
        end

        # Read existing plist file
        plist_path = params[:plist_path]

        UI.user_error!("Couldn't find plist file at path '#{plist_path}'") unless File.exist?(plist_path)
        plist = Xcodeproj::Plist.read_from_path(plist_path)

        params[:block].call(plist) if params[:block]

        # Write changes to file
        Xcodeproj::Plist.write_to_path(plist, plist_path)

        UI.success("Updated #{params[:plist_path]} 💾.")
        File.read(plist_path)
      end

      #####################################################
      # @!group Documentation
      #####################################################

      def self.is_supported?(platform)
        [:ios].include?(platform)
      end

      def self.description
        'Update a plist file'
      end

      def self.details
        "This action allows you to modify any value inside any `plist` file."
      end

      def self.available_options
        [

          FastlaneCore::ConfigItem.new(key: :plist_path,
                                       env_name: "FL_UPDATE_PLIST_PATH",
                                       description: "Path to plist file",
                                       optional: true),
          FastlaneCore::ConfigItem.new(key: :block,
                                       type: :string_callback,
                                       description: 'A block to process plist with custom logic')

        ]
      end

      def self.author
        ["rishabhtayal", "matthiaszarzecki"]
      end

      def self.example_code
        [
          'update_plist( # Updates the CLIENT_ID and GOOGLE_APP_ID string entries in the plist-file
            plist_path: "path/to/your_plist_file.plist",
            block: proc do |plist|
              plist[:CLIENT_ID] = "new_client_id"
              plist[:GOOGLE_APP_ID] = "new_google_app_id"
            end
          )',
          'update_plist( # Sets a boolean entry
            plist_path: "path/to/your_plist_file.plist",
            block: proc do |plist|
              plist[:boolean_entry] = true
            end
          )',
          'update_plist( # Sets a number entry
            plist_path: "path/to/your_plist_file.plist",
            block: proc do |plist|
              plist[:number_entry] = 13
            end
          )',
          'update_plist( # Sets an array-entry with multiple sub-types
            plist_path: "path/to/your_plist_file.plist",
            block: proc do |plist|
              plist[:array_entry] = ["entry_01", true, 1243]
            end
          )',
          'update_plist( # The block can contain logic too
            plist_path: "path/to/your_plist_file.plist",
            block: proc do |plist|
              if options[:environment] == "production"
                plist[:CLIENT_ID] = "new_client_id_production"
              else
                plist[:CLIENT_ID] = "new_client_id_development"
              end
            end
          )',
          'update_plist( # Advanced processing: find URL scheme for particular key and replace value
            plist_path: "path/to/Info.plist",
            block: proc do |plist|
              urlScheme = plist["CFBundleURLTypes"].find{|scheme| scheme["CFBundleURLName"] == "com.acme.default-url-handler"}
              urlScheme[:CFBundleURLSchemes] = ["acme-production"]
            end
          )',
          'update_plist( # Sets an dictionary with multiple sub-types
            plist_path: "path/to/Info.plist",
            block: proc do |plist|
              dic_name = plist["dic_name"]
              dic_name[:sub_dic_key] = "1234" # string、bool or number
            end
          )'
        ]
      end

      def self.category
        :project
      end
    end
  end
end
