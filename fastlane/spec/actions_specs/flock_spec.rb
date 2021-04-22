describe Fastlane do
  describe Fastlane::FastFile do
    describe "Flock Action" do
      FLOCK_BASE_URL = Fastlane::Actions::FlockAction::BASE_URL

      def run_flock(**arguments)
        parsed_arguments = Fastlane::ConfigurationHelper.parse(
          Fastlane::Actions::FlockAction, arguments
        )

        Fastlane::Actions::FlockAction.run(parsed_arguments)
      end

      context 'options' do
        before do
          stub_request(:any, /example.com/)
        end

        around do |example|
          FastlaneSpec::Env.with_env_values(FL_FLOCK_BASE_URL: 'https://example.com') { example.run }
        end

        it 'requires message' do
          expect { run_flock(token: 'xxx') }.to(
            raise_error(FastlaneCore::Interface::FastlaneError) do |error|
              expect(error.message).to match(/message/)
            end
          )
        end

        it 'requires token' do
          expect { run_flock(message: 'xxx') }.to(
            raise_error(FastlaneCore::Interface::FastlaneError) do |error|
              expect(error.message).to match(/token/)
            end
          )
        end

        it 'allows environment variables' do
          FastlaneSpec::Env.with_env_values(
            FL_FLOCK_BASE_URL: 'https://example.com',
            FL_FLOCK_MESSAGE: 'xxx',
            FL_FLOCK_TOKEN: 'xxx'
          ) do
            expect { run_flock }.to_not(raise_error)
          end
        end
      end

      it 'fails on non 200 response' do
        stub_request(:post, "#{FLOCK_BASE_URL}/token").
          to_return(status: 400)
        expect { run_flock(message: 'message', token: 'token') }.to(
          raise_error(FastlaneCore::Interface::FastlaneError) do |error|
            expect(error.message).to match(/Error sending message to Flock/)
          end
        )
      end

      it 'performs POST request with specified options' do
        stub_request(:post, "#{FLOCK_BASE_URL}/token").
          with(body: '{"text":"message"}',
               headers: { 'Content-Type' => 'application/json' }).
          to_return(status: 200)
        run_flock(message: 'message', token: 'token')
      end

      it 'handles quotes in message' do
        message = %("that's what", she said)
        stub_request(:post, //).
          with(body: %({"text":"\\"that's what\\", she said"}))
        run_flock(message: message, token: 'xxx')
      end
    end
  end
end
