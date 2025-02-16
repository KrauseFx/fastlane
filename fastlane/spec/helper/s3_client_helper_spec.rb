describe Fastlane::Helper::S3ClientHelper do
  subject { described_class.new(s3_client: instance_double('Aws::S3::Client')) }

  describe '#find_bucket!' do
    before { class_double('Aws::S3::Bucket', new: bucket).as_stubbed_const }

    context 'when bucket found' do
      let(:bucket) { instance_double('Aws::S3::Bucket', exists?: true) }

      it 'returns bucket' do
        expect(subject.find_bucket!('foo')).to eq(bucket)
      end
    end

    context 'when bucket not found' do
      let(:bucket) { instance_double('Aws::S3::Bucket', exists?: false) }

      it 'raises error' do
        expect { subject.find_bucket!('foo') }.to raise_error("Bucket 'foo' not found")
      end
    end
  end

  describe '#delete_file' do
    it 'deletes s3 object' do
      object = instance_double('Aws::S3::Object', delete: true)
      bucket = instance_double('Aws::S3::Bucket', object: object)

      expect(subject).to receive(:find_bucket!).and_return(bucket)
      expect(object).to receive(:delete)
      subject.delete_file('foo', 'bar')
    end
  end

  describe 'underlying client creation' do
    let(:s3_client) { instance_double('Aws::S3::Client', list_buckets: []) }
    let(:s3_credentials) { instance_double('Aws::Credentials') }

    before { class_double('Aws::Credentials', new: s3_credentials).as_stubbed_const }

    it 'does create with any parameters if none are given' do
      expect(Aws::S3::Client).to receive(:new).with({}).and_return(s3_client)
      described_class.new.list_buckets
    end

    it 'passes region if given' do
      expect(Aws::S3::Client).to receive(:new).with({ region: 'aws-region' }).and_return(s3_client)
      described_class.new(region: 'aws-region').list_buckets
    end

    it 'creates credentials if access_key and secret are given' do
      expect(Aws::S3::Client).to receive(:new).with({ credentials: s3_credentials }).and_return(s3_client)
      described_class.new(access_key: 'access_key', secret_access_key: 'secret_access_key').list_buckets
    end

    it 'creates credentials if access_key, secret_access_key and session_token are given' do
      expect(Aws::S3::Client).to receive(:new).with({ credentials: s3_credentials }).and_return(s3_client)
      described_class.new(access_key: 'access_key', secret_access_key: 'secret_access_key', session_token: 'session_token').list_buckets
    end

    it 'does not create credentials if access_key and secret are blank' do
      expect(Aws::S3::Client).to receive(:new).with({}).and_return(s3_client)
      described_class.new(access_key: '', secret_access_key: '').list_buckets
    end
  end
end
