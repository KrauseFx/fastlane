require 'frameit/config_parser'

describe Frameit do
  describe Frameit::Editor do
    before do
      Frameit.config = {}
    end

    after do
      Frameit.config = nil
    end

    describe "frame!" do
      before do
        allow_any_instance_of(MiniMagick::Tool::Mogrify).to receive(:call) { '' }
        allow(MiniMagick::Image).to receive(:open) { |path| MiniMagick::Image.new(path) }
        allow_any_instance_of(MiniMagick::Image).to receive(:height) { 1334 }
        allow_any_instance_of(MiniMagick::Image).to receive(:width) { 750 }
        allow_any_instance_of(MiniMagick::Image).to receive(:composite) { |instance| instance }
        allow_any_instance_of(MiniMagick::Image).to receive(:format) {}
        allow_any_instance_of(MiniMagick::Image).to receive(:write) {}
        allow_any_instance_of(MiniMagick::Image).to receive(:identify).and_return("0x0+0+0")

        expect(Frameit::Offsets).to receive(:image_offset).and_return({
          "offset" => "+60+225",
          "width" => 752
        })
      end

      it "properly frame screenshots with captions that include apostrophes" do
        expect_any_instance_of(MiniMagick::Tool::Mogrify).to receive(:draw).with("text 0,0 'Don\\'t forget the apostrophes'")
        screenshot_path = './frameit/spec/fixtures/editor/apostrophes.png'
        config = Frameit::ConfigParser.new.load('./frameit/spec/fixtures/editor/Framefile.json').fetch_value(screenshot_path)
        screenshot = Frameit::Screenshot.new(screenshot_path, Frameit::Color::BLACK, config, nil)
        Frameit::Editor.new(screenshot, config).frame!
      end

      it "does not double escape apostrophes" do
        expect_any_instance_of(MiniMagick::Tool::Mogrify).to receive(:draw).with("text 0,0 'Don\\'t forget the apostrophes'")
        screenshot_path = './frameit/spec/fixtures/editor/escaped-apostrophes.png'
        config = Frameit::ConfigParser.new.load('./frameit/spec/fixtures/editor/Framefile.json').fetch_value(screenshot_path)
        screenshot = Frameit::Screenshot.new(screenshot_path, Frameit::Color::BLACK, config, nil)
        Frameit::Editor.new(screenshot, config).frame!
      end
    end

    describe "should_skip?" do
      it "returns true with no matching filter in Framefile.json" do
        screenshot_path = './frameit/spec/fixtures/editor/ignore.png'
        config = Frameit::ConfigParser.new.load('./frameit/spec/fixtures/editor/Framefile.json').fetch_value(screenshot_path)
        screenshot = Frameit::Screenshot.new(screenshot_path, Frameit::Color::BLACK, config, nil)
        skip = Frameit::Editor.new(screenshot, config).should_skip?
        expect(skip).to be(true)
      end
      it "returns false with matching filter in Framefile.json" do
        screenshot_path = './frameit/spec/fixtures/editor/apostrophes.png'
        config = Frameit::ConfigParser.new.load('./frameit/spec/fixtures/editor/Framefile.json').fetch_value(screenshot_path)
        screenshot = Frameit::Screenshot.new(screenshot_path, Frameit::Color::BLACK, config, nil)
        skip = Frameit::Editor.new(screenshot, config).should_skip?
        expect(skip).to be(false)
      end
    end

    describe "fetch_text" do
      context ".strings" do
        it "fetches strings from ../" do
          screenshot_path = './frameit/spec/fixtures/editor/android/en-US/images/phoneScreenshots/screen1.png'
          config = Frameit::ConfigParser.new.load('./frameit/spec/fixtures/editor/Framefile.json').fetch_value(screenshot_path)
          screenshot = Frameit::Screenshot.new(screenshot_path, Frameit::Color::BLACK, config, nil)
          editor = Frameit::Editor.new(screenshot, config)

          # Suppress type validation error
          allow(Fastlane::UI).to receive(:user_error!)

          expect(Frameit::StringsParser).to receive(:parse).and_call_original

          text = editor.send("fetch_text", "title-same-dir")
          expect(text).to eq("Screen1 Title - same dir")
        end

        it "fetches strings from ../../" do
          screenshot_path = './frameit/spec/fixtures/editor/android/en-US/images/phoneScreenshots/screen1.png'
          config = Frameit::ConfigParser.new.load('./frameit/spec/fixtures/editor/Framefile.json').fetch_value(screenshot_path)
          screenshot = Frameit::Screenshot.new(screenshot_path, Frameit::Color::BLACK, config, nil)
          editor = Frameit::Editor.new(screenshot, config)

          # Suppress type validation error
          allow(Fastlane::UI).to receive(:user_error!)

          expect(Frameit::StringsParser).to receive(:parse).and_call_original

          text = editor.send("fetch_text", "title-1-up")
          expect(text).to eq("Screen1 Title - 1 dir up")
        end

        it "fetches strings from ../../../" do
          screenshot_path = './frameit/spec/fixtures/editor/android/en-US/images/phoneScreenshots/screen1.png'
          config = Frameit::ConfigParser.new.load('./frameit/spec/fixtures/editor/Framefile.json').fetch_value(screenshot_path)
          screenshot = Frameit::Screenshot.new(screenshot_path, Frameit::Color::BLACK, config, nil)
          editor = Frameit::Editor.new(screenshot, config)

          # Suppress type validation error
          allow(Fastlane::UI).to receive(:user_error!)

          expect(Frameit::StringsParser).to receive(:parse).and_call_original

          text = editor.send("fetch_text", "title-2-up")
          expect(text).to eq("Screen1 Title - 2 dir up")
        end
      end
    end
  end
end
