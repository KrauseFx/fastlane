require_relative '../print_table'
require_relative '../ui/ui'

module FastlaneCore
  # Responsible for loading configuration files
  class ConfigurationFile
    class ExceptionWhileParsingError < RuntimeError
      attr_reader :wrapped_exception
      attr_reader :recovered_options

      def initialize(wrapped_ex, options)
        @wrapped_exception = wrapped_ex
        @recovered_options = options
      end
    end

    # Available keys from the config file
    attr_accessor :available_keys

    # After loading, contains all the found options
    attr_accessor :options

    # Path to the config file represented by the current object
    attr_accessor :configfile_path

    # @param config [FastlaneCore::Configuration] is used to gather required information about the configuration
    # @param path [String] The path to the configuration file to use
    def initialize(config, path, block_for_missing, skip_printing_values = false)
      self.available_keys = config.all_keys
      self.configfile_path = path
      self.options = {}

      @block_for_missing = block_for_missing
      content = File.read(path, encoding: "utf-8")

      # From https://github.com/orta/danger/blob/master/lib/danger/Dangerfile.rb
      if content.tr!('“”‘’‛', %(""'''))
        UI.error("Your #{File.basename(path)} has had smart quotes sanitised. " \
                  'To avoid issues in the future, you should not use ' \
                  'TextEdit for editing it. If you are not using TextEdit, ' \
                  'you should turn off smart quotes in your editor of choice.')
      end

      begin
        # rubocop:disable Security/Eval
        eval(content) # this is okay in this case
        # rubocop:enable Security/Eval

        print_resulting_config_values unless skip_printing_values # only on success
      rescue SyntaxError => ex
        line = ex.to_s.match(/\(eval\):(\d+)/)[1]
        UI.error("Error in your #{File.basename(path)} at line #{line}")
        UI.content_error(content, line)
        UI.user_error!("Syntax error in your configuration file '#{path}' on line #{line}: #{ex}")
      rescue => ex
        raise ExceptionWhileParsingError.new(ex, self.options), "Error while parsing config file at #{path}"
      end
    end

    def print_resulting_config_values
      require 'terminal-table'
      UI.success("Successfully loaded '#{File.expand_path(self.configfile_path)}' 📄")

      # Show message when self.modified_values is empty
      if self.modified_values.empty?
        UI.important("No values defined in '#{self.configfile_path}'")
        return
      end

      rows = self.modified_values.collect do |key, value|
        [key, value] if value.to_s.length > 0
      end.compact

      puts("")
      puts(Terminal::Table.new(rows: FastlaneCore::PrintTable.transform_output(rows),
                              title: "Detected Values from '#{self.configfile_path}'"))
      puts("")
    end

    # This is used to display only the values that have changed in the summary table
    def modified_values
      @modified_values ||= {}
    end

    def method_missing(method_sym, *arguments, &block)
      # First, check if the key is actually available
      return if self.options.key?(method_sym)

      if self.available_keys.include?(method_sym)

        value = arguments.first
        value = yield if value.nil? && block

        if value.nil?
          unless block
            # The config file has something like this:
            #
            #   clean
            #
            # without specifying a value for the method call
            # or a block. This is most likely a user error
            # So we tell the user that they can provide a value
            warning = ["In the config file '#{self.configfile_path}'"]
            warning << "you have the line #{method_sym}, but didn't provide"
            warning << "any value. Make sure to append a value right after the"
            warning << "option name. Make sure to check the docs for more information"
            UI.important(warning.join(" "))
          end
          return
        end

        self.modified_values[method_sym] = value

        # to support frozen strings (e.g. ENV variables) too
        # we have to dupe the value
        # in < Ruby 2.4.0 `.dup` is not support by boolean values
        # and there is no good way to check if a class actually
        # responds to `dup`, so we have to rescue the exception
        begin
          value = value.dup
        rescue TypeError
          # Nothing specific to do here, if we can't dupe, we just
          # deal with it (boolean values can't be from env variables anyway)
        end
        self.options[method_sym] = value
      else
        # We can't set this value, maybe the tool using this configuration system has its own
        # way of handling this block, as this might be a special block (e.g. ipa block) that's only
        # executed on demand
        if @block_for_missing
          @block_for_missing.call(method_sym, arguments, block)
        else
          self.options[method_sym] = '' # important, since this will raise a good exception for free
        end
      end
    end

    # Override configuration for a specific lane. If received lane name does not
    # match the lane name available as environment variable, no changes will
    # be applied.
    #
    # @param lane_name Symbol representing a lane name.
    # @yield Block to run for overriding configuration values.
    #
    def for_lane(lane_name, &block)
      if ENV["FASTLANE_LANE_NAME"] == lane_name.to_s
        with_a_clean_config_merged_when_complete(&block)
      end
    end

    # Override configuration for a specific platform. If received platform name
    # does not match the platform name available as environment variable, no
    # changes will be applied.
    #
    # @param platform_name Symbol representing a platform name.
    # @yield Block to run for overriding configuration values.
    #
    def for_platform(platform_name, &block)
      if ENV["FASTLANE_PLATFORM_NAME"] == platform_name.to_s
        with_a_clean_config_merged_when_complete(&block)
      end
    end

    # Allows a configuration block (for_lane, for_platform) to get a clean
    # configuration for applying values, so that values can be overridden
    # (once) again. Those values are then merged into the surrounding
    # configuration as the block completes
    def with_a_clean_config_merged_when_complete
      previous_config = self.options.dup
      self.options = {}
      begin
        yield
      ensure
        self.options = previous_config.merge(self.options)
      end
    end
  end
end
