describe Frameit do
  describe Frameit::StringsParser do
    describe "parse" do
      it "raise error when file can't be found" do
        expect do
          Frameit::StringsParser.parse("./nothere")
        end.to raise_exception("Couldn't find strings file at path './nothere'")
      end

      it "raise error when file isn't a .strings file" do
        expect do
          Frameit::StringsParser.parse("./frameit/spec/fixtures/background.jpg")
        end.to raise_exception("Must be .strings file, only got './frameit/spec/fixtures/background.jpg'")
      end

      describe "successfully parsing" do
        it "parses a valid .strings file (utf16)" do
          translations = Frameit::StringsParser.parse("./frameit/spec/fixtures/translations.strings")

          expect(translations).to eq({
            "Cancel" => "Abbrechen",
            "OK" => "OK",
            "Multiple words working" => "einlangesdeutshceswort mit Abstand"
          })
        end

        it "parses a valid .strings file (utf8)" do
          translations = Frameit::StringsParser.parse("./frameit/spec/fixtures/translations.utf8.strings")

          expect(translations).to eq({
            "Cancel" => "Abbrechen",
            "OK" => "OK",
            "Multiple words working" => "einlangesdeutshceswort mit Abstand"
          })
        end

        it "parses a valid .strings file (utf8) with space in path" do
          translations = Frameit::StringsParser.parse("./frameit/spec/fixtures/translations file.utf8.strings")

          expect(translations).to eq({
            "Cancel" => "Abbrechen",
            "OK" => "OK",
            "Multiple words working" => "einlangesdeutshceswort mit Abstand"
          })
        end
      end

      describe "failure parsing" do
        it "logs a helpful message on a bad file" do
          expect(Frameit::UI).to receive(:error).with(/.*translations.bad.strings line 2:/)
          expect(Frameit::UI).to receive(:verbose).with(/undefined method .\[\]. for nil:NilClass/)
          expect(Frameit::UI).to receive(:error).with(/Empty parsing result for .*translations.bad.strings/)

          translations = Frameit::StringsParser.parse("./frameit/spec/fixtures/translations.bad.strings")
          expect(translations).to eq({})
        end

        it "explains that only UTF-8 and UTF-16 encoded are allowed" do
          expect(Frameit::UI).to receive(:error).with(/.*translations.utf32.strings.*UTF16/)

          translations = Frameit::StringsParser.parse("./frameit/spec/fixtures/translations.utf32.strings")
          expect(translations).to eq({})
        end
      end
    end

    describe "encoding_type" do
      let(:path) { "/Users/fastlane/directory/en-US/title.strings" }
      let(:path_with_space) { "/Users/fastlane/directory name/en-US/title.strings" }

      it "escapes path with no spaces" do
        expect(Fastlane::Helper).to receive(:backticks)
          .with("file --mime-encoding #{path}", print: false)
          .and_return("").exactly(1).times

        Frameit::StringsParser.encoding_type(path)
      end

      it "escapes path with spaces" do
        escaped_path = path_with_space.shellescape
        expect(Fastlane::Helper).to receive(:backticks)
          .with("file --mime-encoding #{escaped_path}", print: false)
          .and_return("").exactly(1).times

        Frameit::StringsParser.encoding_type(path_with_space)
      end
    end
  end
end
