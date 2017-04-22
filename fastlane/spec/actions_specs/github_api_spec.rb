describe Fastlane do
  describe Fastlane::FastFile do
    describe "github_api" do
      let(:response_body) { File.read("./fastlane/spec/fixtures/requests/github_create_file_response.json") }

      context 'successful' do
         before do
          stub_request(:put, "https://api.github.com/repos/fastlane/fastlane/contents/TEST_FILE.md").
            with( headers: {
                    'Authorization' => 'Basic MTIzNDU2Nzg5',
                    'Host'=>'api.github.com:443',
                    'User-Agent' => 'fastlane-github_api'
                  }).
            to_return(status: 200, body: response_body, headers: {})
        end

        context 'with a hash body' do
          it 'correctly submits to github api' do
            result = Fastlane::FastFile.new.parse("
              lane :test do
                github_api(
                  api_token: '123456789',
                  secure: false,
                  debug: true,
                  http_method: 'PUT',
                  path: 'repos/fastlane/fastlane/contents/TEST_FILE.md',
                  body: {
                    path: 'TEST_FILE.md',
                    message: 'File committed',
                    content: 'VGVzdCBDb250ZW50Cg==\n',
                    branch: 'test-branch'
                  }
                )
              end
            ").runner.execute(:test)

            expect(result[:status]).to eq(200)
            expect(result[:response]).to be_a(Excon::Response)
            expect(result[:response].body).to eq(response_body)
            expect(result[:json]).to eq(JSON.parse(response_body))
          end
        end

        context 'with raw JSON body' do
          it 'correctly submits to github api' do
            result = Fastlane::FastFile.new.parse(%Q{
              lane :test do
                github_api(
                  api_token: '123456789',
                  secure: false,
                  debug: true,
                  http_method: 'PUT',
                  path: 'repos/fastlane/fastlane/contents/TEST_FILE.md',
                  body: '{
                      "path":"TEST_FILE.md",
                      "message":"File committed",
                      "content":"VGVzdCBDb250ZW50Cg==\\\\n",
                      "branch":"test-branch"
                    }'
                  )
              end
            }).runner.execute(:test)

            expect(result[:status]).to eq(200)
            expect(result[:response]).to be_a(Excon::Response)
            expect(result[:response].body).to eq(response_body)
            expect(result[:json]).to eq(JSON.parse(response_body))
          end
        end

        it 'allows calling as a block for success from other actions' do
          expect do
            Fastlane::FastFile.new.parse(%Q{
              lane :test do
                Fastlane::Actions::GithubApiAction.run(
                  server_url: 'https://api.github.com',
                  api_token: '123456789',
                  secure: false,
                  debug: true,
                  http_method: 'PUT',
                  path: 'repos/fastlane/fastlane/contents/TEST_FILE.md',
                  body: '{
                      "path":"TEST_FILE.md",
                      "message":"File committed",
                      "content":"VGVzdCBDb250ZW50Cg==\\\\n",
                      "branch":"test-branch"
                    }'
                  ) do |result|
                    UI.user_error!("Success block triggered with \#{result[:response].body}")
                  end
              end
            }).runner.execute(:test)
          end.to raise_error(FastlaneCore::Interface::FastlaneError) do |error|
            expect(error.message).to match("Success block triggered with #{response_body}")
          end
        end
      end

      context 'failures' do
        let(:error_response_body) { '{"message":"Bad credentials","documentation_url":"https://developer.github.com/v3"}' }

        before do
          stub_request(:put, "https://api.github.com/repos/fastlane/fastlane/contents/TEST_FILE.md").
            with( headers: {
                    'Authorization' => 'Basic MTIzNDU2Nzg5',
                    'Host'=>'api.github.com:443',
                    'User-Agent' => 'fastlane-github_api'
                  }).
            to_return(status: 401, body: error_response_body, headers: {})
        end

        it "raises on error by default" do
          expect do
            Fastlane::FastFile.new.parse("
              lane :test do
                github_api(
                  api_token: '123456789',
                  secure: false,
                  debug: true,
                  http_method: 'PUT',
                  path: 'repos/fastlane/fastlane/contents/TEST_FILE.md',
                  body: {
                    path: 'TEST_FILE.md',
                    message: 'File committed',
                    content: 'VGVzdCBDb250ZW50Cg==\n',
                    branch: 'test-branch'
                  }
                )
              end
            ").runner.execute(:test)
          end.to raise_error(FastlaneCore::Interface::FastlaneError) do |error|
            expect(error.message).to match("GitHub responded with 401")
          end
        end

        it "allows custom error handling by status code" do
          expect do
            Fastlane::FastFile.new.parse("
              lane :test do
                github_api(
                  api_token: '123456789',
                  secure: false,
                  debug: true,
                  http_method: 'PUT',
                  path: 'repos/fastlane/fastlane/contents/TEST_FILE.md',
                  body: {
                    path: 'TEST_FILE.md',
                    message: 'File committed',
                    content: 'VGVzdCBDb250ZW50Cg==\n',
                    branch: 'test-branch'
                  },
                  errors: {
                    401 => Proc.new {|result|
                      UI.user_error!(\"Custom error handled for 401 \#{result[:response].body}\")
                    },
                    404 => Proc.new do |result|
                      UI.message('not found')
                    end
                  }
                )
              end
            ").runner.execute(:test)
          end.to raise_error(FastlaneCore::Interface::FastlaneError) do |error|
            expect(error.message).to match("Custom error handled for 401 #{error_response_body}")
          end
        end

        it "doesn't raise on custom error handling" do
          result = Fastlane::FastFile.new.parse("
            lane :test do
              github_api(
                api_token: '123456789',
                secure: false,
                debug: true,
                http_method: 'PUT',
                path: 'repos/fastlane/fastlane/contents/TEST_FILE.md',
                body: {
                  path: 'TEST_FILE.md',
                  message: 'File committed',
                  content: 'VGVzdCBDb250ZW50Cg==\n',
                  branch: 'test-branch'
                },
                errors: {
                  401 => Proc.new {|result|
                    UI.message(\"error handled\")
                  }
                }
              )
            end
          ").runner.execute(:test)

          expect(result[:status]).to eq(401)
          expect(result[:response]).to be_a(Excon::Response)
          expect(result[:response].body).to eq(error_response_body)
          expect(result[:json]).to eq(JSON.parse(error_response_body))
        end
      end
    end
  end
end
