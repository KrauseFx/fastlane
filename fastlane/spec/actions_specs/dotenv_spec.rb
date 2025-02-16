describe Fastlane do

  describe Fastlane::Actions::DotenvAction do
    describe "dotenv" do
      describe "when dotenv exists" do
        describe "overloads" do
          it "dotenv from default directory" do
            expect(Fastlane::Helper::DotenvHelper).to receive(:find_dotenv_directory).and_return('/base/path/').times.twice
            expect(Dotenv).to receive(:overload).with('/base/path/.env.secret')

            allow(File).to receive(:exist?).with(anything).and_call_original
            expect(File).to receive(:exist?).with('/base/path/.env.secret').and_return(true)

            Fastlane::FastFile.new.parse("lane :test do
              dotenv(name: 'secret')
            end").runner.execute(:test)
          end

          it "dotenv from custom directory" do
            expect(Dotenv).to receive(:overload).with('platforms/ios/.env.release')

            allow(File).to receive(:exist?).with(anything).and_call_original
            expect(File).to receive(:exist?).with('platforms/ios/.env.release').and_return(true)

            Fastlane::FastFile.new.parse("lane :test do
              dotenv(name: 'release', path: 'platforms/ios')
            end").runner.execute(:test)
          end
        end

        describe "loads" do
          it "dotenv from default directory" do
            expect(Fastlane::Helper::DotenvHelper).to receive(:find_dotenv_directory).and_return('/base/path/').times.twice
            expect(Dotenv).to receive(:load).with('/base/path/.env.secret')

            allow(File).to receive(:exist?).with(anything).and_call_original
            expect(File).to receive(:exist?).with('/base/path/.env.secret').and_return(true)

            Fastlane::FastFile.new.parse("lane :test do
              dotenv(name: 'secret', overload: false)
            end").runner.execute(:test)
          end

          it "dotenv from custom directory" do
            expect(Dotenv).to receive(:load).with('platforms/ios/.env.release')

            allow(File).to receive(:exist?).with(anything).and_call_original
            expect(File).to receive(:exist?).with('platforms/ios/.env.release').and_return(true)

            Fastlane::FastFile.new.parse("lane :test do
              dotenv(name: 'release', path: 'platforms/ios', overload: false)
            end").runner.execute(:test)
          end
        end
      end

      describe "when dotenv doesn't exist" do
        it "fails silently with custom directory" do
          allow(File).to receive(:exist?).with(anything).and_call_original
          expect(File).to receive(:exist?).with('platforms/ios/.env.release').and_return(false)

          expect(UI).to receive(:error).with("Cannot find dotenv file at 'platforms/ios/.env.release'")

          Fastlane::FastFile.new.parse("lane :test do
            dotenv(name: 'release', path: 'platforms/ios')
          end").runner.execute(:test)
        end

        it "fails silently with custom directory" do
          allow(File).to receive(:exist?).with(anything).and_call_original
          expect(File).to receive(:exist?).with('platforms/ios/.env.release').and_return(false)

          expect do
            Fastlane::FastFile.new.parse("lane :test do
                dotenv(name: 'release', path: 'platforms/ios', fail_if_missing: true)
              end").runner.execute(:test)
          end.to raise_error("Cannot find dotenv file at 'platforms/ios/.env.release'")
        end
      end
    end
  end
end
