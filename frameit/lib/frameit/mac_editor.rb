require 'mini_magick'
require_relative 'editor'

module Frameit
  # Responsible for framing Mac Screenshots
  class MacEditor < Editor
    def prepare_image
      image = super
      image.resize("#{offset['width']}x") if offset['width']
    end

    def put_device_into_background(background)
      @image = background.composite(image, "png") do |c|
        c.compose("Over")
        c.geometry(offset['offset'])
      end

      return image
    end

    def load_frame
      nil # Macs don't need frames - backgrounds only
    end

    def is_complex_framing_mode?
      true # Mac screenshots always need a background
    end

    def generate_background
      MiniMagick::Image.open(@config['background']) # no resizing on the Mac
    end
  end
end
