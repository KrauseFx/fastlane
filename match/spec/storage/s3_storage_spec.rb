describe Match do
  describe Match::Storage::S3Storage do
    subject { described_class.new(s3_region: nil, s3_access_key: nil, s3_secret_access_key: nil, s3_session_token: nil, s3_bucket: 'foobar') }
    let(:working_directory) { '/var/folders/px/abcdefghijklmnop/T/d20181026-96528-1av4gge' }

    before do
      allow(subject).to receive(:working_directory).and_return(working_directory)
      allow(subject).to receive(:s3_client).and_return(s3_client)
    end

    describe '#upload_files' do
      let(:files_to_upload) do
        [
          "#{working_directory}/ABCDEFG/certs/development/ABCDEFG.cer",
          "#{working_directory}/ABCDEFG/certs/development/ABCDEFG.p12"
        ]
      end
      let(:s3_client) { double(upload_file: true) }
      let!(:file) { class_double('File', read: 'body').as_stubbed_const }

      it 'reads the correct files from local storage' do
        files_to_upload.each do |file_name|
          expect(file).to receive(:read).with(file_name)
        end

        subject.upload_files(files_to_upload: files_to_upload)
      end

      it 'uploads files to the correct path in remote storage' do
        expect(s3_client).to receive(:upload_file).with('foobar', 'ABCDEFG/certs/development/ABCDEFG.cer', 'body', 'private')
        expect(s3_client).to receive(:upload_file).with('foobar', 'ABCDEFG/certs/development/ABCDEFG.p12', 'body', 'private')
        subject.upload_files(files_to_upload: files_to_upload)
      end

      it 'uploads files with s3_object_prefix if set' do
        allow(subject).to receive(:s3_object_prefix).and_return('123456/')

        expect(s3_client).to receive(:upload_file).with('foobar', '123456/ABCDEFG/certs/development/ABCDEFG.cer', 'body', 'private')
        expect(s3_client).to receive(:upload_file).with('foobar', '123456/ABCDEFG/certs/development/ABCDEFG.p12', 'body', 'private')
        subject.upload_files(files_to_upload: files_to_upload)
      end
    end

    describe '#delete_files' do
      let(:files_to_upload) do
        [
          "#{working_directory}/ABCDEFG/certs/development/ABCDEFG.cer",
          "#{working_directory}/ABCDEFG/certs/development/ABCDEFG.p12"
        ]
      end
      let(:s3_client) { double(delete_file: true) }

      it 'deletes files with correct paths' do
        expect(s3_client).to receive(:delete_file).with('foobar', 'ABCDEFG/certs/development/ABCDEFG.cer')
        expect(s3_client).to receive(:delete_file).with('foobar', 'ABCDEFG/certs/development/ABCDEFG.p12')

        subject.delete_files(files_to_delete: files_to_upload)
      end

      it 'deletes files with s3_object_prefix if set' do
        allow(subject).to receive(:s3_object_prefix).and_return('123456/')

        expect(s3_client).to receive(:delete_file).with('foobar', '123456/ABCDEFG/certs/development/ABCDEFG.cer')
        expect(s3_client).to receive(:delete_file).with('foobar', '123456/ABCDEFG/certs/development/ABCDEFG.p12')

        subject.delete_files(files_to_delete: files_to_upload)
      end
    end

    describe '#download' do
      let(:files_to_download) do
        [
          instance_double('Aws::S3::Object', key: 'TEAMID1/certs/development/CERTID1.cer', download_file: true),
          instance_double('Aws::S3::Object', key: 'TEAMID1/certs/development/CERTID1.p12', download_file: true),
          instance_double('Aws::S3::Object', key: 'TEAMID2/certs/development/CERTID2.cer', download_file: true),
          instance_double('Aws::S3::Object', key: 'TEAMID2/certs/development/CERTID2.p12', download_file: true)
        ]
      end
      let(:bucket) { instance_double('Aws::S3::Bucket') }
      let(:s3_client) { instance_double('Fastlane::Helper::S3ClientHelper', find_bucket!: bucket) }

      def stub_bucket_content(objects: files_to_download)
        allow(bucket).to receive(:objects) do |options|
          objects.select { |file_object| file_object.key.start_with?(options[:prefix] || '') }
        end
      end

      before { class_double('FileUtils', mkdir_p: true).as_stubbed_const }

      it 'downloads to correct working directory' do
        stub_bucket_content
        files_to_download.each do |file_object|
          expect(file_object).to receive(:download_file).with("#{working_directory}/#{file_object.key}")
        end

        subject.download
      end

      it 'only downloads files specific to the provided team' do
        stub_bucket_content
        allow(subject).to receive(:team_id).and_return('TEAMID2')
        files_to_download.each do |file_object|
          if file_object.key.start_with?('TEAMID2')
            expect(file_object).to receive(:download_file).with("#{working_directory}/#{file_object.key}")
          else
            expect(file_object).not_to receive(:download_file)
          end
        end

        subject.download
      end

      it 'downloads files and strips the s3_object_prefix for working_directory path' do
        allow(subject).to receive(:s3_object_prefix).and_return('123456/')

        prefixed_objects = files_to_download.map do |obj|
          instance_double('Aws::S3::Object', key: "123456/#{obj.key}", download_file: true)
        end
        stub_bucket_content(objects: prefixed_objects)

        prefixed_objects.each do |file_object|
          expect(file_object).to receive(:download_file).with("#{working_directory}/#{file_object.key.delete_prefix('123456/')}")
        end

        subject.download
      end

      it 'downloads only file-like objects and skips folder-like objects' do
        valid_object = files_to_download[0]
        invalid_object = instance_double('Aws::S3::Object', key: 'ABCDEFG/certs/development/')

        allow(s3_client).to receive_message_chain(:find_bucket!, :objects).and_return([valid_object, invalid_object])

        expect(valid_object).to receive(:download_file).with("#{working_directory}/#{valid_object.key}")
        expect(invalid_object).not_to receive(:download_file).with("#{working_directory}/#{invalid_object.key}")

        subject.download
      end
    end
  end
end
