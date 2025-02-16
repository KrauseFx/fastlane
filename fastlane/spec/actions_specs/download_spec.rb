describe Fastlane do
  describe Fastlane::FastFile do
    describe "download" do
      before do
        stub_request(:get, "https://google.com/remoteFile.json").
          to_return(status: 200, body: { status: :ok }.to_json, headers: {})

        stub_request(:get, "https://google.com/timeout.json").to_timeout
      end

      it "downloads the file from a remote server" do
        url = "https://google.com/remoteFile.json"
        result = Fastlane::FastFile.new.parse("lane :test do
          download(url: '#{url}')
        end").runner.execute(:test)

        correct = { 'status' => 'ok' }
        expect(result).to eq(correct)
        expect(Fastlane::Actions.lane_context[Fastlane::Actions::SharedValues::DOWNLOAD_CONTENT]).to eq(correct)
      end

      it "properly handles network failures" do
        expect do
          url = "https://google.com/timeout.json"
          result = Fastlane::FastFile.new.parse("lane :test do
            download(url: '#{url}')
          end").runner.execute(:test)
        end.to raise_error("Error fetching remote file: execution expired")
      end

      it "file contents is store in the sensitive lane context" do
        url = "https://google.com/remoteFile.json"
        result = Fastlane::FastFile.new.parse("lane :test do
          download(url: '#{url}', sensitive: true)
        end").runner.execute(:test)

        correct = { 'status' => 'ok' }
        expect(result).to eq(correct)
        sensitive_context = Fastlane::Actions.lane_context.instance_variable_get(:@sensitive_context)
        expect(sensitive_context[Fastlane::Actions::SharedValues::DOWNLOAD_CONTENT]).not_to be_nil
      end

      it "returns the downloaded JSON as plain text" do
        url = "https://google.com/remoteFile.json"
        result = Fastlane::FastFile.new.parse("lane :test do
          download(url: '#{url}', plain_text: true)
        end").runner.execute(:test)

        expect(result).to be_kind_of(String)
        expect(Fastlane::Actions.lane_context[Fastlane::Actions::SharedValues::DOWNLOAD_CONTENT]).to be_kind_of(String)
      end
    end
  end
end
