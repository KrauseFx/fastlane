require 'mini_magick'

require_relative 'template_finder'
require_relative 'trim_box'
require_relative 'module'
require_relative 'offsets'
require_relative 'config_parser'
require_relative 'strings_parser'
require_relative 'device_types'

module Frameit
  # Currently the class is 2 lines too long. Reevaluate refactoring when it's length changes significantly
  class Editor # rubocop:disable Metrics/ClassLength
    attr_accessor :screenshot # reference to the screenshot object to fetch the path, title, etc.
    attr_accessor :debug_mode
    attr_accessor :frame_path
    attr_accessor :frame # the frame of the device
    attr_accessor :image # the current image used for editing
    attr_accessor :space_to_device

    def initialize(screenshot, config, debug_mode = false)
      @screenshot = screenshot
      @config = config
      self.debug_mode = debug_mode
    end

    def frame!
      prepare_image

      @frame_path = load_frame
      if @frame_path # Mac doesn't need a frame
        self.frame = MiniMagick::Image.open(@frame_path)
        # Rotate the frame according to the device orientation
        self.frame.rotate(self.rotation_for_device_orientation)
      elsif self.instance_of?(Editor)
        # Couldn't find device frame (probably an iPhone 4, for which there are no images available any more)
        # Message is already shown elsewhere
        return
      end

      if is_complex_framing_mode?
        @image = complex_framing
      else
        # easy mode from 1.0 - no title or background
        put_into_frame # put it in the frame
      end

      store_result # write to file system
    end

    def load_frame
      color = fetch_frame_color
      if color
        screenshot.color = color
      end
      TemplateFinder.get_template(screenshot)
    end

    def prepare_image
      @image = MiniMagick::Image.open(screenshot.path)
    end

    def rotation_for_device_orientation
      return 90 if self.screenshot.landscape_right?
      return -90 if self.screenshot.landscape_left?
      return 0
    end

    def should_skip?
      return is_complex_framing_mode? && !fetch_text(:title)
    end

    private

    def store_result
      output_path = screenshot.output_path
      image.format("png")
      image.write(output_path)
      Helper.hide_loading_indicator
      UI.success("Added frame: '#{File.expand_path(output_path)}'")
    end

    # puts the screenshot into the frame
    def put_into_frame
      # We have to rotate the screenshot, since the offset information is for portrait
      # only. Instead of doing the calculations ourselves, it's much easier to let
      # imagemagick do the hard lifting for landscape screenshots
      rotation = self.rotation_for_device_orientation
      frame.rotate(-rotation)
      @image.rotate(-rotation)

      # Debug Mode: Add filename to frame
      if self.debug_mode
        filename = File.basename(@frame_path, ".*")
        filename.sub!('Apple', '') # remove 'Apple'

        width = screenshot.size[0]
        font_size = width / 20 # magic number that works well

        offset_top = offset['offset'].split("+")[2].to_f
        annotate_offset = "+0+#{offset_top}" # magic number that works semi well

        frame.combine_options do |c|
          c.gravity('North')
          c.undercolor('#00000080')
          c.fill('white')
          c.pointsize(font_size)
          c.annotate(annotate_offset.to_s, filename.to_s)
        end
      end

      @image = frame.composite(image, "png") do |c|
        c.compose("DstOver")
        c.geometry(offset['offset'])
      end

      # Revert the rotation from above
      frame.rotate(rotation)
      @image.rotate(rotation)
    end

    def offset
      return @offset_information if @offset_information

      @offset_information = @config['offset'] || Offsets.image_offset(screenshot).dup

      if @offset_information && (@offset_information['offset'] || @offset_information['offset'])
        return @offset_information
      end
      UI.user_error!("Could not find offset_information for '#{screenshot}'")
    end

    #########################################################################################
    # Everything below is related to title, background, etc. and is not used in the easy mode
    #########################################################################################

    # this is used to correct the 1:1 offset information
    # the offset information is stored to work for the template images
    # since we resize the template images to have higher quality screenshots
    # we need to modify the offset information by a certain factor
    def modify_offset(multiplicator)
      # Format: "+133+50"
      hash = offset['offset']
      x = hash.split("+")[1].to_f * multiplicator
      y = hash.split("+")[2].to_f * multiplicator
      new_offset = "+#{x.round}+#{y.round}"
      @offset_information['offset'] = new_offset
    end

    # Do we add a background and title as well?
    def is_complex_framing_mode?
      return (@config['background'] and (@config['title'] or @config['keyword']))
    end

    # more complex mode: background, frame and title
    def complex_framing
      background = generate_background

      self.space_to_device = vertical_frame_padding

      if @config['title']
        background = put_title_into_background(background, @config['stack_title'])
      end

      if self.frame # we have no frame on le mac
        resize_frame!
        put_into_frame

        # Decrease the size of the framed screenshot to fit into the defined padding + background
        frame_width = background.width - horizontal_frame_padding * 2
        frame_height = background.height - effective_text_height - vertical_frame_padding

        if @config['show_complete_frame']
          # calculate the final size of the screenshot to resize in one go
          # it may be limited either by the width or height of the frame
          image_aspect_ratio = @image.width.to_f / @image.height.to_f
          image_width = [frame_width, @image.width].min
          image_height = [frame_height, image_width / image_aspect_ratio].min
          image_width = image_height * image_aspect_ratio
          @image.resize("#{image_width}x#{image_height}") if image_width < @image.width || image_height < @image.height
        else
          # the screenshot size is only limited by width.
          # If higher than the frame, the screenshot is cut off at the bottom
          @image.resize("#{frame_width}x") if frame_width < @image.width
        end
      end

      @image = put_device_into_background(background)

      image
    end

    # Horizontal adding around the frames
    def horizontal_frame_padding
      padding = @config['padding']
      if padding.kind_of?(String) && padding.split('x').length == 2
        padding = padding.split('x')[0]
        padding = padding.to_i unless padding.end_with?('%')
      end
      return scale_padding(padding)
    end

    # Vertical adding around the frames
    def vertical_frame_padding
      padding = @config['padding']
      if padding.kind_of?(String) && padding.split('x').length == 2
        padding = padding.split('x')[1]
        padding = padding.to_i unless padding.end_with?('%')
      end
      return scale_padding(padding)
    end

    # Minimum height for the title
    def title_min_height
      @title_min_height ||= begin
        height = @config['title_min_height'] || 0
        if height.kind_of?(String) && height.end_with?('%')
          height = ([image.width, image.height].min * height.to_f * 0.01).ceil
        end
        height
      end
    end

    def scale_padding(padding)
      if padding.kind_of?(String) && padding.end_with?('%')
        padding = ([image.width, image.height].min * padding.to_f * 0.01).ceil
      end
      multi = 1.0
      multi = 1.7 if self.screenshot.triple_density?
      return padding * multi
    end

    def effective_text_height
      [space_to_device, title_min_height].max
    end

    def device_top(background)
      @device_top ||= if title_below_image
                        background.height - effective_text_height - image.height
                      else
                        effective_text_height
                      end
    end

    def title_below_image
      @title_below_image ||= @config['title_below_image']
    end

    # Returns a correctly sized background image
    def generate_background
      background = MiniMagick::Image.open(@config['background'])

      if background.height != screenshot.size[1]
        background.resize("#{screenshot.size[0]}x#{screenshot.size[1]}^") # `^` says it should fill area
        background.merge!(["-gravity", "center", "-crop", "#{screenshot.size[0]}x#{screenshot.size[1]}+0+0"]) # crop from center
      end
      background
    end

    def put_device_into_background(background)
      left_space = (background.width / 2.0 - image.width / 2.0).round

      @image = background.composite(image, "png") do |c|
        colorspace = image.data["colorspace"]
        c.colorspace(colorspace) if colorspace

        c.compose("Over")
        c.geometry("+#{left_space}+#{device_top(background)}")
      end

      return image
    end

    # Resize the frame as it's too low quality by default
    def resize_frame!
      screenshot_width = self.screenshot.portrait? ? screenshot.size[0] : screenshot.size[1]

      multiplicator = (screenshot_width.to_f / offset['width'].to_f) # by how much do we have to change this?
      new_frame_width = multiplicator * frame.width # the new width for the frame
      frame.resize("#{new_frame_width.round}x") # resize it to the calculated width
      modify_offset(multiplicator) # modify the offset to properly insert the screenshot into the frame later
    end

    def resize_text(text)
      width = text.width
      ratio = width / (image.width.to_f - horizontal_frame_padding * 2)
      if ratio > 1.0
        # too large - resizing now
        text.resize("#{((1.0 / ratio) * text.width).round}x")
      end
    end

    # Add the title above or below the device
    def put_title_into_background_stacked(background, title, keyword)
      resize_text(title)
      resize_text(keyword)

      vertical_padding = vertical_frame_padding # assign padding to variable
      spacing_between_title_and_keyword = (actual_font_size('keyword') / 2)
      title_left_space = (background.width / 2.0 - title.width / 2.0).round
      keyword_left_space = (background.width / 2.0 - keyword.width / 2.0).round

      self.space_to_device += title.height + keyword.height + spacing_between_title_and_keyword + vertical_padding

      if title_below_image
        keyword_top = background.height - effective_text_height / 2 - (keyword.height + spacing_between_title_and_keyword + title.height) / 2
      else
        keyword_top = device_top(background) / 2 - spacing_between_title_and_keyword / 2 - keyword.height
      end
      title_top = keyword_top + keyword.height + spacing_between_title_and_keyword

      # keyword
      background = background.composite(keyword, "png") do |c|
        c.compose("Over")
        c.geometry("+#{keyword_left_space}+#{keyword_top}")
      end
      # Place the title below the keyword
      background.composite(title, "png") do |c|
        c.compose("Over")
        c.geometry("+#{title_left_space}+#{title_top}")
      end
    end

    def put_title_into_background(background, stack_title)
      text_images = build_text_images(image.width - 2 * horizontal_frame_padding, image.height - 2 * vertical_frame_padding, stack_title)

      keyword = text_images[:keyword]
      title = text_images[:title]

      if stack_title && !keyword.nil? && !title.nil? && keyword.width > 0 && title.width > 0
        background = put_title_into_background_stacked(background, title, keyword)
        return background
      end
      # sum_width: the width of both labels together including the space in-between
      #   is used to calculate the ratio
      sum_width = title.width
      sum_width += keyword.width + keyword_padding if keyword

      title_below_image = @config['title_below_image']

      # Resize the 2 labels if they exceed the available space either horizontally or vertically:
      image_scale_factor = 1.0 # default
      ratio_horizontal = sum_width / (image.width.to_f - horizontal_frame_padding * 2) # The fraction of the text images compared to the left and right padding
      ratio_vertical = title.height.to_f / effective_text_height # The fraction of the actual height of the images compared to the available space
      if ratio_horizontal > 1.0 || ratio_vertical > 1.0
        # If either is too large, resize with the maximum ratio:
        image_scale_factor = (1.0 / [ratio_horizontal, ratio_vertical].max)

        UI.verbose("Text for image #{self.screenshot.path} is quite long, reducing font size by #{(100 * (1.0 - image_scale_factor)).round(1)}%")

        title.resize("#{(image_scale_factor * title.width).round}x")
        keyword.resize("#{(image_scale_factor * keyword.width).round}x") if keyword
        sum_width *= image_scale_factor
      end

      vertical_padding = vertical_frame_padding # assign padding to variable
      left_space = (background.width / 2.0 - sum_width / 2.0).round

      self.space_to_device += actual_font_size('title') + vertical_padding

      if title_below_image
        title_top = background.height - effective_text_height / 2 - title.height / 2
      else
        title_top = device_top(background) / 2 - title.height / 2
      end

      # First, put the keyword on top of the screenshot, if we have one
      if keyword
        background = background.composite(keyword, "png") do |c|
          c.compose("Over")
          c.geometry("+#{left_space}+#{title_top}")
        end

        left_space += keyword.width + (keyword_padding * image_scale_factor)
      end

      # Then, put the title on top of the screenshot next to the keyword
      background.composite(title, "png") do |c|
        c.compose("Over")
        c.geometry("+#{left_space}+#{title_top}")
      end
    end

    def actual_font_size(key)
      font_size = @config[key.to_s]['font_size']
      return font_size if !font_size.nil? && font_size > 0

      font_scale_factor = @config['font_scale_factor'] || 0.1
      UI.user_error!("Parameter 'font_scale_factor' can not be 0. Please provide a value larger than 0.0 (default = 0.1).") if font_scale_factor == 0.0
      [@image.width * font_scale_factor].max.round
    end

    # The space between the keyword and the title
    def keyword_padding
      (actual_font_size('keyword') / 3.0).round
    end

    # This will build up to 2 individual images with the title and optional keyword, which will then be added to the real image
    def build_text_images(max_width, max_height, stack_title)
      words = [:keyword, :title].keep_if { |a| fetch_text(a) } # optional keyword/title
      results = {}
      trim_boxes = {}
      top_vertical_trim_offset = Float::INFINITY # Init at a large value, as the code will search for a minimal value.
      bottom_vertical_trim_offset = 0
      words.each do |key|
        # Create empty background
        empty_path = File.join(Frameit::ROOT, "lib/assets/empty.png")
        text_image = MiniMagick::Image.open(empty_path)
        image_height = max_height # gets trimmed afterwards anyway, and on the iPad the `y` would get cut
        text_image.combine_options do |i|
          # Oversize as the text might be larger than the actual image. We're trimming afterwards anyway
          i.resize("#{max_width * 5.0}x#{image_height}!") # `!` says it should ignore the ratio
        end

        current_font = font(key)
        text = fetch_text(key)
        UI.verbose("Using #{current_font} as font the #{key} of #{screenshot.path}") if current_font
        UI.verbose("Adding text '#{text}'")

        text.gsub!('\n', "\n")
        text.gsub!(/(?<!\\)(')/) { |s| "\\#{s}" } # escape unescaped apostrophes with a backslash

        interline_spacing = @config['interline_spacing']

        # Add the actual title
        text_image.combine_options do |i|
          i.font(current_font) if current_font
          i.weight(@config[key.to_s]['font_weight']) if @config[key.to_s]['font_weight']
          i.gravity("Center")
          i.pointsize(actual_font_size(key))
          i.draw("text 0,0 '#{text}'")
          i.interline_spacing(interline_spacing) if interline_spacing
          i.fill(@config[key.to_s]['color'])
        end

        results[key] = text_image

        # Natively trimming the image with .trim will result in the loss of the common baseline between the text in all images when side-by-side (e.g. stack_title is false).
        # Hence retrieve the calculated trim bounding box without actually trimming:
        calculated_trim_box = text_image.identify do |b|
          b.format("%@") # CALCULATED: trim bounding box (without actually trimming), see: http://www.imagemagick.org/script/escape.php
        end

        # Create a Trimbox object from the MiniMagick .identify string with syntax "<width>x<height>+<offset_x>+<offset_y>":
        trim_box = Frameit::Trimbox.new(calculated_trim_box)

        # Get the minimum top offset of the trim box:
        if trim_box.offset_y < top_vertical_trim_offset
          top_vertical_trim_offset = trim_box.offset_y
        end

        # Get the maximum bottom offset of the trim box, this is the top offset + height:
        if (trim_box.offset_y + trim_box.height) > bottom_vertical_trim_offset
          bottom_vertical_trim_offset = trim_box.offset_y + trim_box.height
        end

        # Store for the crop action:
        trim_boxes[key] = trim_box
      end

      # Crop text images:
      words.each do |key|
        # Get matching trim box:
        trim_box = trim_boxes[key]

        # For side-by-side text images (e.g. stack_title is false) adjust the trim box based on top_vertical_trim_offset and bottom_vertical_trim_offset to maintain the text baseline:
        unless stack_title
          # Determine the trim area by maintaining the same vertical top offset based on the smallest value from all trim boxes (top_vertical_trim_offset).
          # When the vertical top offset is larger than the smallest vertical top offset, the trim box needs to be adjusted:
          if trim_box.offset_y > top_vertical_trim_offset
            # Increase the height of the trim box with the difference in vertical top offset:
            trim_box.height += trim_box.offset_y - top_vertical_trim_offset
            # Change the vertical top offset to match that of the others:
            trim_box.offset_y = top_vertical_trim_offset

            UI.verbose("Trim box for key \"#{key}\" is adjusted to align top: #{trim_box}\n")
          end

          # Check if the height needs to be adjusted to reach the bottom offset:
          if (trim_box.offset_y + trim_box.height) < bottom_vertical_trim_offset
            # Set the height of the trim box to the difference between vertical bottom and top offset:
            trim_box.height = bottom_vertical_trim_offset - trim_box.offset_y

            UI.verbose("Trim box for key \"#{key}\" is adjusted to align bottom: #{trim_box}\n")
          end
        end

        # Crop image with (adjusted) trim box parameters in MiniMagick string format:
        results[key].crop(trim_box.string_format)
      end

      results
    end

    # Fetches the title + keyword for this particular screenshot
    def fetch_text(type)
      UI.user_error!("Valid parameters :keyword, :title") unless [:keyword, :title].include?(type)

      # Try to get it from a keyword.strings or title.strings file
      strings_path = File.join(File.expand_path("../", screenshot.path), "#{type}.strings")
      strings_path = File.join(File.expand_path("../../", screenshot.path), "#{type}.strings") unless File.exist?(strings_path)
      strings_path = File.join(File.expand_path("../../../", screenshot.path), "#{type}.strings") unless File.exist?(strings_path)
      if File.exist?(strings_path)
        parsed = StringsParser.parse(strings_path)
        text_array = parsed.find { |k, v| screenshot.path.upcase.include?(k.upcase) }
        return text_array.last if text_array && text_array.last.length > 0 # Ignore empty string
      end

      UI.verbose("Falling back to text in Framefile.json as there was nothing specified in the #{type}.strings file")

      # No string files, fallback to Framefile config
      text = @config[type.to_s]['text'] if @config[type.to_s] && @config[type.to_s]['text'] && @config[type.to_s]['text'].length > 0 # Ignore empty string
      return text
    end

    def fetch_frame_color
      color = @config['frame']
      unless color.nil?
        Frameit::Color.constants.each do |c|
          constant = Frameit::Color.const_get(c)
          if color == constant.upcase.gsub(' ', '_')
            return constant
          end
        end
      end

      return nil
    end

    # The font we want to use
    def font(key)
      single_font = @config[key.to_s]['font']
      return single_font if single_font

      fonts = @config[key.to_s]['fonts']
      if fonts
        fonts.each do |font|
          if font['supported']
            font['supported'].each do |language|
              if screenshot.language == language
                return font["font"]
              end
            end
          else
            # No `supported` array, this will always be true
            UI.verbose("Found a font with no list of supported languages, using this now")
            return font["font"]
          end
        end
      end

      UI.verbose("No custom font specified for #{screenshot}, using the default one")
      return nil
    end
  end
end
