describe Fastlane do
  describe Fastlane::FastFile do
    describe "Increment Version Number Integration" do
      {
          "1" => "2",
          "1.1" => "1.2",
          "1.1.1" => "1.1.2"
      }.each do |from_version, to_version|
        it "increments all targets' version number from #{from_version} to #{to_version}" do
          expect(Fastlane::Actions).to receive(:sh)
            .with(/agvtool what-marketing-version/, any_args)
            .once
            .and_return(from_version)
          Fastlane::FastFile.new.parse("lane :test do
            increment_version_number
          end").runner.execute(:test)

          expect(Fastlane::Actions.lane_context[Fastlane::Actions::SharedValues::VERSION_NUMBER]).to match(/cd .* && agvtool new-marketing-version #{to_version}/)
        end
      end

      ["1.0", "10"].each do |version|
        it "raises an exception when trying to increment patch version number for #{version} (which has no patch number)" do
          expect(Fastlane::Actions).to receive(:sh)
            .with(/agvtool what-marketing-version/, any_args)
            .once
            .and_return(version)

          expect do
            Fastlane::FastFile.new.parse("lane :test do
              increment_version_number(bump_type: 'patch')
            end").runner.execute(:test)
          end.to raise_error("Can't increment version")
        end
      end

      {
        "1.0.0" => "1.1.0",
        "10.13" => "10.14"
      }.each do |from_version, to_version|
        it "increments all targets' minor version number from #{from_version} to #{to_version}" do
          expect(Fastlane::Actions).to receive(:sh)
            .with(/agvtool what-marketing-version/, any_args)
            .once
            .and_return(from_version)
          Fastlane::FastFile.new.parse("lane :test do
            increment_version_number(bump_type: 'minor')
          end").runner.execute(:test)

          expect(Fastlane::Actions.lane_context[Fastlane::Actions::SharedValues::VERSION_NUMBER]).to match(/cd .* && agvtool new-marketing-version #{to_version}/)
        end
      end

      it "raises an exception when trying to increment minor version number for 12 (which has no minor number)" do
        expect(Fastlane::Actions).to receive(:sh)
          .with(/agvtool what-marketing-version/, any_args)
          .once
          .and_return("12")

        expect do
          Fastlane::FastFile.new.parse("lane :test do
            increment_version_number(bump_type: 'minor')
          end").runner.execute(:test)
        end.to raise_error("Can't increment version")
      end

      {
        "1.0.0" => "2.0.0",
        "10.13" => "11.0",
        "12" => "13"
      }.each do |from_version, to_version|
        it "it increments all targets' major version number from #{from_version} to #{to_version}" do
          expect(Fastlane::Actions).to receive(:sh)
            .with(/agvtool what-marketing-version/, any_args)
            .once
            .and_return(from_version)
          Fastlane::FastFile.new.parse("lane :test do
            increment_version_number(bump_type: 'major')
          end").runner.execute(:test)

          expect(Fastlane::Actions.lane_context[Fastlane::Actions::SharedValues::VERSION_NUMBER]).to match(/cd .* && agvtool new-marketing-version #{to_version}/)
        end
      end

      ["1.4.3", "1.0", "10"].each do |version|
        it "passes a custom version number #{version}" do
          result = Fastlane::FastFile.new.parse("lane :test do
            increment_version_number(version_number: \"#{version}\")
          end").runner.execute(:test)

          expect(Fastlane::Actions.lane_context[Fastlane::Actions::SharedValues::VERSION_NUMBER]).to match(/cd .* && agvtool new-marketing-version #{version}/)
        end
      end

      it "prefers a custom version number over a boring version bump" do
        Fastlane::FastFile.new.parse("lane :test do
          increment_version_number(version_number: '1.77.3', bump_type: 'major')
        end").runner.execute(:test)

        expect(Fastlane::Actions.lane_context[Fastlane::Actions::SharedValues::VERSION_NUMBER]).to match(/cd .* && agvtool new-marketing-version 1.77.3/)
      end

      it "automatically removes new lines from the version number" do
        Fastlane::FastFile.new.parse("lane :test do
          increment_version_number(version_number: '1.77.3\n', bump_type: 'major')
        end").runner.execute(:test)

        expect(Fastlane::Actions.lane_context[Fastlane::Actions::SharedValues::VERSION_NUMBER]).to end_with("&& agvtool new-marketing-version 1.77.3")
      end

      it "returns the new version as return value" do
        expect(Fastlane::Actions).to receive(:sh)
          .with(/agvtool what-marketing-version/, any_args)
          .once
          .and_return("1.0.0")
        result = Fastlane::FastFile.new.parse("lane :test do
          increment_version_number(bump_type: 'major')
        end").runner.execute(:test)

        expect(result).to eq(Fastlane::Actions.lane_context[Fastlane::Actions::SharedValues::VERSION_NUMBER])
      end

      it "raises an exception when xcode project path wasn't found" do
        expect do
          Fastlane::FastFile.new.parse("lane :test do
            increment_version_number(xcodeproj: '/nothere')
          end").runner.execute(:test)
        end.to raise_error("Could not find Xcode project")
      end

      it "raises an exception when user passes workspace" do
        expect do
          Fastlane::FastFile.new.parse("lane :test do
            increment_version_number(xcodeproj: 'project.xcworkspace')
          end").runner.execute(:test)
        end.to raise_error("Please pass the path to the project, not the workspace")
      end

      ["A", "1.2.3.4", "1.2.3-pre"].each do |version|
        it "raises an exception when unable to calculate new version for #{version} (which does not match any of the supported schemes)" do
          expect(Fastlane::Actions).to receive(:sh)
            .with(/agvtool what-marketing-version/, any_args)
            .once
            .and_return(version)
          expect do
            Fastlane::FastFile.new.parse("lane :test do
              increment_version_number
            end").runner.execute(:test)
          end.to raise_error("Your current version (#{version}) does not respect the format A or A.B or A.B.C")
        end
      end

      it "raises an exception when version_number is not formatted as a SemVer" do
        expect do
          Fastlane::FastFile.new.parse("lane :test do
            increment_version_number(version_number: 'release/1.2.3')
          end").runner.execute(:test)
        end.to raise_error("The version_number parameter (release/1.2.3) does not respect the format A or A.B or A.B.C")
      end
    end
  end
end
