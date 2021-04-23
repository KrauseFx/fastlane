require_relative "../module"

module Spaceship
  module Tunes
    # A definition of different styled displays used by devices
    # that App Store Connect supports storing screenshots.
    # Display styles often only vary based on screen resolution
    # however other aspects of a displays physical appearance are
    # also factored (i.e if the home indicator is provided via
    # a hardware button or a software interface).
    class DisplayFamily
      # The display family name from the App Store Connect API that
      # is used when uploading or listing screenshots. This value is
      # then assigned to the
      # Spaceship::Tunes::AppScreenshot#device_type attribute.
      attr_accessor :name

      # The user friendly name of this definition.
      #
      # Source: Media Manager in App Store Connect.
      attr_accessor :friendly_name

      # The user friendly category for this definition (i.e iPhone,
      # Apple TV or Desktop).
      attr_accessor :friendly_category_name

      # An array of supported screen resolutions (in pixels) that are
      # supported for the associated device.
      #
      # Source: https://help.apple.com/app-store-connect/#/devd274dd925
      attr_accessor :screenshot_resolutions

      # An internal identifier for the same device definition used
      # in the DUClient.
      #
      # Source: You can find this by uploading an image in App Store
      # Connect using your browser and then look for the
      # X-Apple-Upload-Validation-RuleSets value in the uploads
      # request headers.
      attr_accessor :picture_type

      # Similar to `picture_type`, but for iMessage screenshots.
      attr_accessor :messages_picture_type

      # Identifies if the device definition supports iMessage screenshots.
      def messages_supported?
        true unless messages_picture_type.nil?
      end

      # Finds a DisplayFamily definition.
      #
      # @param name (Symbol|String) The name of the display family being searched for.
      # @return DisplayFamily object matching the given name.
      def self.find(name)
        name = name.to_sym if name.kind_of?(String)
        lookup[name]
      end

      # All DisplayFamily types currently supported by App Store Connect.
      def self.all
        lookup.values
      end

      def self.lookup
        return @lookup if defined?(@lookup)
        display_families = JSON.parse(File.read(File.join(Spaceship::ROOT, "lib", "assets", "displayFamilies.json")))
        @lookup ||= display_families.map { |data| [data["name"].to_sym, DisplayFamily.new(data)] }.to_h
      end

      private

      def initialize(data)
        @name = data["name"]
        @friendly_name = data["friendly_name"]
        @friendly_category_name = data["friendly_category_name"]
        @screenshot_resolutions = data["screenshot_resolutions"]
        @picture_type = data["picture_type"]
        @messages_picture_type = data["messages_picture_type"]
      end
    end
  end
end
