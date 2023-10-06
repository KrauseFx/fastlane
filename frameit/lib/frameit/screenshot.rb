require_relative 'editor'
require_relative 'mac_editor'
require_relative 'device_types'
require_relative 'module'
require_relative 'device'

module Frameit
  # Represents one screenshot
  class Screenshot
    attr_accessor :path # path to the screenshot
    attr_accessor :size # size in px array of 2 elements: height and width
    attr_accessor :device # device detected according to resolution, priority and settings
    attr_accessor :color # the color to use for the frame (from Frameit::Color)

    # path: Path to screenshot
    # color: Color to use for the frame
    def initialize(path, color, config, platform_command)
      UI.user_error!("Couldn't find file at path '#{path}'") unless File.exist?(path)
      @color = color
      @path = path
      @size = FastImage.size(path)

      # There are three ways how we can get settings to Frameit:
      # - options.rb
      #   - gets parameters via CLI (e. g. fastlane run frameit use_platform:"android") or fastfile (Fastlane's global
      #     settings for a given project)
      #   - see Parameters in the doc
      #   - contains default values and validates values
      #   - accessed via Frameit.config[:key]
      #   - default value is either general platform from fastfile or IOS if run directly
      #   - lowest priority
      # - commands_generator.rb
      #   - commands entered directly to CLI (e. g. fastlane frameit android)
      #   - they are passed via constructors to other classes
      #   - higher priority than options.rb (user may enter a command to override fastfile's global setting)
      # - config_parser.rb
      #   - gets key / values from Framefile.json
      #   - see Advanced usage in the doc
      #   - both default and specific values can be entered in the file (filtered by file name)
      #   - accessed via ConfigParser.fetch_value(screenshot.path)[key] (the ConfigParser's instance is passed
      #     to Screenshot's constructor as config, i.e. we call config[key])
      #   - should have the highest priority, because user might set a specific value for a specific screenshot which
      #     should override CLI parameters and fastfile global setting
      platform = config['use_platform'] || platform_command || Frameit.config[:use_platform]
      @device = Device.find_device_by_id_or_name(config['force_device_type'] || Frameit.config[:force_device_type]) || Device.detect_device(path, platform)
    end

    # Device name for a given screen size. Used to use the correct template
    def device_name
      @device.formatted_name
      # rubocop:enable Require/MissingRequireStatement
    end

    def default_color
      @device.default_color
    end

    def deliver_screen_id
      @device.deliver_screen_id
    end

    # Is the device a 3x device? (e.g. iPhone 6 Plus, iPhone X)
    def triple_density?
      !device.density_ppi.nil? && device.density_ppi > 400
    end

    # Super old devices (iPhone 4)
    def mini?
      !device.density_ppi.nil? && device.density_ppi < 300
    end

    def mac?
      device_name == 'Apple MacBook'
    end

    # The name of the orientation of a screenshot. Used to find the correct template
    def orientation_name
      return Orientation::PORTRAIT if size[0] < size[1]
      return Orientation::LANDSCAPE
    end

    def frame_orientation
      filename = File.basename(self.path, ".*")
      block = Frameit.config[:force_orientation_block]

      unless block.nil?
        orientation = block.call(filename)
        valid = [:landscape_left, :landscape_right, :portrait, nil]
        UI.user_error("orientation_block must return #{valid[0..-2].join(', ')} or nil") unless valid.include?(orientation)
      end

      puts("Forced orientation: #{orientation}") unless orientation.nil?

      return orientation unless orientation.nil?
      return :portrait if self.orientation_name == Orientation::PORTRAIT
      return :landscape_right # Default landscape orientation
    end

    def portrait?
      return (frame_orientation == :portrait)
    end

    def landscape_left?
      return (frame_orientation == :landscape_left)
    end

    def landscape_right?
      return (frame_orientation == :landscape_right)
    end

    def landscape?
      return self.landscape_left? || self.landscape_right
    end

    def output_path
      path.gsub('.png', '_framed.png').gsub('.PNG', '_framed.png')
    end

    # If the framed screenshot was generated *before* the screenshot file,
    # then we must be outdated.
    def outdated?
      return true unless File.exist?(output_path)
      return File.mtime(path) > File.mtime(output_path)
    end

    def language
      @language ||= Pathname.new(path).parent.basename.to_s
    end

    def to_s
      self.path
    end
  end
end
