require 'fastimage'

require_relative 'module'

module Deliver
  # AppClipHeaderImage represents one app clip header image for one specific locale.
  class AppClipHeaderImage
    attr_accessor :path
    attr_accessor :language

    # @param path (String) path to the app clip header image file
    # @param language (String) Language of this app clip header image (e.g. en-US)
    def initialize(path, language)
      self.path = path
      self.language = language
    end
  end
end
