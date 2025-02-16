require 'dotenv'

module Fastlane
  module Actions
    class DotenvAction < Action
      def self.run(params)
        env_file = ".env.#{params[:name]}"
        path = params[:path]
        overload = params[:overload]
        fail_if_missing = params[:fail_if_missing]

        env_path = File.join(path, env_file)

        if !File.exist?(env_path)
          error = "Cannot find dotenv file at '#{env_path}'"

          if fail_if_missing
            UI.user_error!(error)
          end

          UI.error(error)
        elsif overload
          UI.success("Overloading environment variables from '#{env_path}'")
          Dotenv.overload(env_path)
        else
          UI.success("Loading environment variables from '#{env_path}'")
          Dotenv.load(env_path)
        end
      end

      def self.author
        "joshdholtz"
      end

      def self.available_options
        [
          FastlaneCore::ConfigItem.new(key: :name,
                                       env_name: 'FL_DOTENV_NAME',
                                       description: 'Load an dotenv file by name. E.g.: ios, android, secret'),
          FastlaneCore::ConfigItem.new(key: :path,
                                       env_name: 'FL_DOTENV_PATH',
                                       description: 'Directory where the dotenv file is located. Defaults to working directory',
                                       default_value: Fastlane::Helper::DotenvHelper.find_dotenv_directory,
                                       default_value_dynamic: true),
          FastlaneCore::ConfigItem.new(key: :overload,
                                       env_name: 'FL_DOTENV_OVERLOAD',
                                       description: 'Whether environment variables should be overloaded',
                                       default_value: true,
                                       type: Boolean),
          FastlaneCore::ConfigItem.new(key: :fail_if_missing,
                                       env_name: 'FL_DOTENV_FAIL_IF_MISSING',
                                       description: 'Raises an error if the dotenv file cannot be found',
                                       default_value: false,
                                       type: Boolean)
        ]
      end

      def self.description
        "Loads a dotenv file by name and optionally in a non-standard path"
      end

      def self.category
        :misc
      end

      def self.is_supported?(platform)
        true
      end

      def self.example_code
        [
          'dotenv(
            name: "secret" # Looks for .env.secret
          )',
          'dotenv(
            name: "release",
            path: "platforms/ios"
          )',
          'dotenv(
            name: "secret",
            fail_if_missing: true
          )'
        ]
      end
    end
  end
end
