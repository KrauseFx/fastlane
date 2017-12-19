require "rubygems"

module FastlaneCore
  # Utility class to construct a Gem::Version from a tag.
  # Accepts vX.Y.Z and X.Y.Z.
  class TagVersion < Gem::Version
    class << self
      def correct?(tag)
        superclass.correct?(version_number_from_tag(tag))
      end

      # Gem::Version.new barfs on things like "v0.1.0", which is the style
      # generated by the rake release task. Just strip off any initial v
      # to generate a Gem::Version from a tag.
      def version_number_from_tag(tag)
        tag.sub(/^v/, "")
      end
    end

    def initialize(tag)
      super(self.class.version_number_from_tag(tag))
    end
  end
end
