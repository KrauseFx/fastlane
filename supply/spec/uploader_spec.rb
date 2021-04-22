require 'fileutils'

describe Supply do
  describe Supply::Uploader do
    before do
      Supply.config = {}
    end

    after do
      Supply.config = {}
    end

    describe "#verify_config!" do
      let(:subject) { Supply::Uploader.new }

      it "raises error if empty config" do
        Supply.config = {}
        expect do
          subject.verify_config!
        end.to raise_error("No local metadata, apks, aab, or track to promote were found, make sure to run `fastlane supply init` to setup supply")
      end

      it "raises error if only track" do
        Supply.config = {
          track: 'alpha'
        }
        expect do
          subject.verify_config!
        end.to raise_error("No local metadata, apks, aab, or track to promote were found, make sure to run `fastlane supply init` to setup supply")
      end

      it "raises error if only track_promote_to" do
        Supply.config = {
          track_promote_to: 'beta'
        }
        expect do
          subject.verify_config!
        end.to raise_error("No local metadata, apks, aab, or track to promote were found, make sure to run `fastlane supply init` to setup supply")
      end

      it "does not raise error if only metadata" do
        Supply.config = {
          metadata_path: 'some/path'
        }
        subject.verify_config!
      end

      it "does not raise error if only apk" do
        Supply.config = {
          apk: 'some/path/app.apk'
        }
        subject.verify_config!
      end

      it "does not raise error if only apk_paths" do
        Supply.config = {
          apk_paths: ['some/path/app1.apk', 'some/path/app2.apk']
        }
        subject.verify_config!
      end

      it "does not raise error if only aab" do
        Supply.config = {
          aab: 'some/path/app1.aab'
        }
        subject.verify_config!
      end

      it "does not raise error if only aab_paths" do
        Supply.config = {
          aab_paths: ['some/path/app1.aab', 'some/path/app2.aab']
        }
        subject.verify_config!
      end

      it "does not raise error if only track and track_promote_to" do
        Supply.config = {
          track: 'alpha',
          track_promote_to: 'beta'
        }
        subject.verify_config!
      end
    end

    describe "#find_obbs" do
      let(:subject) { Supply::Uploader.new }

      before(:all) do
        @obb_dir = Dir.mktmpdir('supply')
        @apk_path = File.join(@obb_dir, 'my.apk')
      end

      def create_obb(name)
        path = "#{@obb_dir}/#{name}"
        FileUtils.touch(path)
        path
      end

      before do
        FileUtils.rm_rf(Dir.glob("#{@obb_dir}/*.obb"))
      end

      def find_obbs
        subject.send(:find_obbs, @apk_path)
      end

      it "finds no obb when there's none to find" do
        expect(find_obbs.count).to eq(0)
      end

      it "skips unrecognized obbs" do
        main_obb = create_obb('unknown.obb')
        expect(find_obbs.count).to eq(0)
      end

      it "finds one match and one patch obb" do
        main_obb = create_obb('main.obb')
        patch_obb = create_obb('patch.obb')
        obbs = find_obbs
        expect(obbs.count).to eq(2)
        expect(obbs).to eq({ 'main' => main_obb, 'patch' => patch_obb })
      end

      it "finds zero obb if too main mains" do
        create_obb('main.obb')
        create_obb('other.main.obb')
        obbs = find_obbs
        expect(obbs.count).to eq(0)
      end

      it "finds zero obb if too many patches" do
        create_obb('patch.obb')
        create_obb('patch.other.obb')
        obbs = find_obbs
        expect(obbs.count).to eq(0)
      end
    end

    describe 'metadata encoding' do
      it 'prints a user friendly error message if metadata is not UTF-8 encoded' do
        fake_config = 'fake config'
        allow(fake_config).to receive(:[]).and_return('fake config value')
        Supply.config = fake_config

        allow(File).to receive(:exist?).and_return(true)
        allow(File).to receive(:read).and_return("fake content")

        fake_listing = "listing"
        Supply::AVAILABLE_METADATA_FIELDS.each do |field|
          allow(fake_listing).to receive("#{field}=".to_sym)
        end

        expect(fake_listing).to receive(:save).and_raise(Encoding::InvalidByteSequenceError)
        expect(FastlaneCore::UI).to receive(:user_error!).with(/Metadata must be UTF-8 encoded./)

        Supply::Uploader.new.upload_metadata('en-US', fake_listing)
      end
    end

    describe '.all_languages' do
      it 'only grabs directories' do
        metadata_path = 'supply/spec/fixtures/metadata/android'
        only_directories = Supply::Uploader.all_languages(metadata_path)
        expect(only_directories).to eq(['en-US', 'fr-FR', 'ja-JP'])
      end
    end

    describe '#promote_track' do
      subject { Supply::Uploader.new.promote_track }

      let(:client) { double('client') }
      let(:version_codes) { [1, 2, 3] }
      let(:config) { { track: 'alpha', track_promote_to: 'beta' } }
      let(:track) { double('alpha') }
      let(:release) { double('release1') }

      before do
        Supply.config = config
        allow(Supply::Client).to receive(:make_from_config).and_return(client)
        allow(client).to receive(:tracks).and_return([track])
        allow(track).to receive(:releases).and_return([release])
        allow(track).to receive(:releases=)

        allow(client).to receive(:track_version_codes).and_return(version_codes)
        allow(client).to receive(:update_track).with(config[:track], 0.1, nil)
        allow(client).to receive(:update_track).with(config[:track_promote_to], 0.1, version_codes)

        allow(release).to receive(:status).and_return(Supply::ReleaseStatus::COMPLETED)
      end

      it 'should only update track once' do
        expect(release).to receive(:status=).with(Supply::ReleaseStatus::COMPLETED)
        expect(release).to receive(:user_fraction=).with(nil)

        expect(client).not_to(receive(:update_track).with(config[:track], anything))
        expect(client).to receive(:update_track).with(config[:track_promote_to], track).once
        subject
      end
    end

    describe '#perform_upload' do
      let(:client) { double('client') }
      let(:config) { { apk: 'some/path/app.apk' } }

      before do
        Supply.config = config
        allow(Supply::Client).to receive(:make_from_config).and_return(client)
        allow(client).to receive(:upload_apk).with(config[:apk]).and_return(1) # newly uploaded version code
        allow(client).to receive(:begin_edit).and_return(nil)
        allow(client).to receive(:commit_current_edit!).and_return(nil)
      end

      it 'should update track with correct version codes' do
        uploader = Supply::Uploader.new
        expect(uploader).to receive(:update_track).with([1]).once
        uploader.perform_upload
      end
    end
  end
end
