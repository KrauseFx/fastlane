require_relative 'module'
require_relative 'app_screenshot'
require_relative 'app_screenshot_validator'
require_relative 'app_clip_header_image'
require_relative 'upload_metadata'
require_relative 'languages'

module Deliver
  module Loader
    # The directory 'appleTV' and `iMessage` are special folders that will cause our screenshot gathering code to iterate
    # through it as well searching for language folders.
    APPLE_TV_DIR_NAME = "appleTV".freeze
    IMESSAGE_DIR_NAME = "iMessage".freeze
    DEFAULT_DIR_NAME = "default".freeze

    EXPANDABLE_DIR_NAMES = [APPLE_TV_DIR_NAME, IMESSAGE_DIR_NAME].freeze
    SPECIAL_DIR_NAMES = [APPLE_TV_DIR_NAME, IMESSAGE_DIR_NAME, DEFAULT_DIR_NAME].freeze

    # Some exception directories may exist from other actions that should not be iterated through
    SUPPLY_DIR_NAME = "android".freeze
    FRAMEIT_FONTS_DIR_NAME = "fonts".freeze
    META_DIR_NAMES = UploadMetadata::ALL_META_SUB_DIRS.map(&:downcase)

    EXCEPTION_DIRECTORIES = (META_DIR_NAMES << SUPPLY_DIR_NAME << FRAMEIT_FONTS_DIR_NAME).freeze

    # A class that represents language folder under screenshots or metadata folder
    class LanguageFolder
      attr_reader :path

      # @return [String] A normalized language name that corresponds to the directory's name
      attr_reader :language

      def self.available_languages
        # 2020-08-24 - Available locales are not available as an endpoint in App Store Connect
        # Update with Spaceship::Tunes.client.available_languages.sort (as long as endpoint is available)
        Deliver::Languages::ALL_LANGUAGES
      end

      def self.allowed_directory_names_with_case
        available_languages + SPECIAL_DIR_NAMES
      end

      # @param path [String] A directory path otherwise this initializer fails
      # @param nested [Boolean] Whether given path is nested of another special directory.
      #  This affects `expandable?` to return `false` when this set to `true`.
      def initialize(path, nested: false)
        raise(ArgumentError, "Given path must be a directory path - #{path}") unless File.directory?(path)
        @path = path
        @language = self.class.available_languages.find { |lang| basename.casecmp?(lang) }
        @nested = nested
      end

      def nested?
        @nested
      end

      def valid?
        self.class.allowed_directory_names_with_case.any? { |name| name.casecmp?(basename) }
      end

      def expandable?
        !nested? && EXPANDABLE_DIR_NAMES.any? { |name| name.casecmp?(basename) }
      end

      def skip?
        EXCEPTION_DIRECTORIES.map(&:downcase).include?(basename.downcase)
      end

      def file_paths(extensions = '{png,jpg,jpeg}')
        Dir.glob(File.join(path, "*.#{extensions}"), File::FNM_CASEFOLD).sort
      end

      def framed_file_paths(extensions = '{png,jpg,jpeg}')
        Dir.glob(File.join(path, "*_framed.#{extensions}"), File::FNM_CASEFOLD).sort
      end

      def basename
        File.basename(@path)
      end
    end

    # Returns the list of valid app screenshot. When detecting invalid screenshots, this will cause an error.
    #
    # @param root [String] A directory path
    # @param ignore_validation [String] Set false not to raise the error when finding invalid folder name
    # @return [Array<Deliver::AppScreenshot>] The list of AppScreenshot that exist under given `root` directory
    def self.load_app_screenshots(root, ignore_validation)
      screenshots = language_folders(root, ignore_validation, true).flat_map do |language_folder|
        paths = if language_folder.framed_file_paths.count > 0
                  UI.important("Framed screenshots are detected! 🖼 Non-framed screenshot files may be skipped. 🏃")
                  # watchOS screenshots can be picked up even when framed ones were found since frameit doesn't support watchOS screenshots
                  framed_or_watch, skipped = language_folder.file_paths.partition { |path| path.downcase.include?('framed') || path.downcase.include?('watch') }
                  skipped.each { |path| UI.important("🏃 Skipping screenshot file: #{path}") }
                  framed_or_watch
                else
                  language_folder.file_paths
                end
        paths.map { |path| AppScreenshot.new(path, language_folder.language) }
      end

      errors = []
      valid_screenshots = screenshots.select { |screenshot| Deliver::AppScreenshotValidator.validate(screenshot, errors) }

      errors_to_skip, errors_to_crash = errors.partition(&:to_skip)

      unless errors_to_skip.empty?
        UI.important("🏃 Screenshots to be skipped are detected!")
        errors_to_skip.each { |error| UI.message(error) }
      end

      unless errors_to_crash.empty?
        UI.important("🚫 Invalid screenshots were detected! Here are the reasons:")
        errors_to_crash.each { |error| UI.error(error) }
        UI.user_error!("Canceled uploading screenshots. Please check the error messages above and fix the screenshots.")
      end

      valid_screenshots
    end

    # Returns the list of valid app clip header images. When detecting invalid header images, this
    # will cause an error. There may only be a max of one image per language and each image must be
    # exactly 1800x1200.
    #
    # @param root [String] A directory path
    # @param ignore_validation [String] Set false not to raise the error when
    # finding invalid folder name @return [Array<Deliver::AppClipHeaderImage>]
    # The list of AppClipHeaderImage that exists under given `root` directory
    def self.load_app_clip_header_images(root, ignore_validation)
      app_clip_header_images = language_folders(root, ignore_validation, true).flat_map do |language_folder|
        paths = language_folder.file_paths
        paths.map { |path| AppClipHeaderImage.new(path, language_folder.language) }
      end

      # validate the header images are 1800x1200 in size
      app_clip_header_images.each do |header_image|
        size = FastImage.size(header_image.path)
        if size.nil?
          UI.user_error!("Unable to read app clip header image file: #{header_image.path}")
        end
        size = size.join('x')
        unless size.eql?("1800x1200")
          UI.user_error!("App clip header images must be exactly 1800x1200 in size. Offending image has size #{size}: '#{header_image.path}'")
        end
      end

      # validate there is only one header image per language
      app_clip_header_images.map(&:language).each do |language|
        if app_clip_header_images.find_all { |header_image| header_image.language.eql?(language) }.length > 1
          UI.user_error!("There can only be one app clip header image per language. The language #{language} has more than one image.")
        end
      end

      app_clip_header_images
    end

    # Returns the list of language folders
    #
    # @param roort [String] A directory path to get the list of language folders
    # @param ignore_validation [Boolean] Set false not to raise the error when finding invalid folder name
    # @param expand_sub_folders [Boolean] Set true to expand special folders; such as "iMessage" to nested language folders
    # @return [Array<LanguageFolder>] The list of LanguageFolder whose each of them
    def self.language_folders(root, ignore_validation, expand_sub_folders = false)
      folders = Dir.glob(File.join(root, '*'))
                   .select { |path| File.directory?(path) }
                   .map { |path| LanguageFolder.new(path, nested: false) }
                   .reject(&:skip?)

      selected_folders, rejected_folders = folders.partition(&:valid?)

      if !ignore_validation && !rejected_folders.empty?
        rejected_folders = rejected_folders.map(&:basename)
        UI.user_error!("Unsupported directory name(s) for screenshots/metadata in '#{root}': #{rejected_folders.join(', ')}" \
                       "\nValid directory names are: #{LanguageFolder.allowed_directory_names_with_case}" \
                       "\n\nEnable 'ignore_language_directory_validation' to prevent this validation from happening")
      end

      # Expand selected_folders for the special directories
      if expand_sub_folders
        selected_folders = selected_folders.flat_map do |folder|
          if folder.expandable?
            Dir.glob(File.join(folder.path, '*'))
               .select { |p| File.directory?(p) }
               .map { |p| LanguageFolder.new(p, nested: true) }
               .select(&:valid?)
          else
            folder
          end
        end
      end

      selected_folders
    end
  end
end
