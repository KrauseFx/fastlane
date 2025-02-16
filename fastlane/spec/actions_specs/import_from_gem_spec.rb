require 'tmpdir'

describe Fastlane do
  describe Fastlane::FastFile do
    describe "import_from_spec" do
      it "raises an exception when no gem is given" do
        expect do
          Fastlane::FastFile.new.parse("lane :test do
            import_from_gem
          end").runner.execute(:test)
        end.to raise_error("Please pass a gem name to the `import_from_gem` action")
      end

      it "loads all fastfile paths specified and find the lanes" do
        Bundler.with_unbundled_env do
          Dir.chdir("fastlane/spec/fixtures/plugins/ImportFromGem") do
            path = Dir.mktmpdir
            `bundle config set --local path #{path}`
            `bundle install`
            output = `bundle exec fastlane lanes`
            expect(output.index("----- fastlane first")).not_to eq(nil)
            expect(output.index("----- fastlane second")).not_to eq(nil)
          end
        end
      end

      it "runs imported actions from an imported gem" do
        Bundler.with_unbundled_env do
          Dir.chdir("fastlane/spec/fixtures/plugins/ImportFromGem") do
            path = Dir.mktmpdir
            `bundle config set --local path #{path}`
            `bundle install`
            output = `bundle exec fastlane first`
            expect(output.index("Step: example_action")).not_to eq(nil)
            expect(output.index("App automation done right")).not_to eq(nil)
          end
        end
      end
    end
  end
end
