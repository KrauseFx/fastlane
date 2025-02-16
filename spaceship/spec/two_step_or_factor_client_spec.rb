require_relative 'mock_servers'

describe Spaceship::Client do
  class TwoStepOrFactorClient < Spaceship::Client
    def self.hostname
      "http://example.com"
    end

    def ask_for_2fa_code(text)
      '123'
    end

    def choose_phone_number(opts)
      opts.first
    end

    def store_cookie(path: nil)
      true
    end

    # these tests actually "send requests" - and `update_request_headers` would otherwise
    # add data to the headers that does not exist / is empty which will crash faraday later
    def update_request_headers(req)
      req
    end
  end

  let(:subject) { TwoStepOrFactorClient.new }

  let(:phone_numbers_json_string) do
    '
      [
        { "id" : 1, "numberWithDialCode" : "+49 •••• •••••85", "obfuscatedNumber" : "•••• •••••85", "pushMode" : "sms" },
        { "id" : 2, "numberWithDialCode" : "+49 ••••• •••••81", "obfuscatedNumber" : "••••• •••••81", "pushMode" : "sms" },
        { "id" : 3, "numberWithDialCode" : "+1 (•••) •••-••66", "obfuscatedNumber" : "(•••) •••-••66", "pushMode" : "sms" },
        { "id" : 4, "numberWithDialCode" : "+39 ••• ••• ••71", "obfuscatedNumber" : "••• ••• ••71", "pushMode" : "sms" },
        { "id" : 5, "numberWithDialCode" : "+353 •• ••• ••43", "obfuscatedNumber" : "••• ••• •43", "pushMode" : "sms" },
        { "id" : 6, "numberWithDialCode" : "+375 • ••• •••-••-59", "obfuscatedNumber" : "• ••• •••-••-59", "pushMode" : "sms" },
        { "id" : 7, "numberWithDialCode" : "+91 •••••• •••60", "obfuscatedNumber" : "•••••• •••60", "pushMode" : "sms" }
      ]
    '
  end
  let(:phone_numbers) { JSON.parse(phone_numbers_json_string) }

  describe 'phone_id_from_number' do
    {
      "+49 123 4567885" => 1,
      "+4912341234581" => 2,
      "+1-123-456-7866" => 3,
      "+39 123 456 7871" => 4,
      "+353123456743" => 5,
      "+375 00 000-00-59" => 6,
      "+91 7654321060" => 7
    }.each do |number_to_test, expected_phone_id|
      it "selects correct phone id #{expected_phone_id} for provided phone number #{number_to_test}" do
        phone_id = subject.phone_id_from_number(phone_numbers, number_to_test)
        expect(phone_id).to eq(expected_phone_id)
      end
    end

    it "raises an error with unknown phone number" do
      phone_number = 'la le lu'
      expect do
        phone_id = subject.phone_id_from_number(phone_numbers, phone_number)
      end.to raise_error(Spaceship::Tunes::Error)
    end
  end

  describe 'handle_two_factor' do
    let(:trusted_devices_response) { JSON.parse(File.read(File.join('spaceship', 'spec', 'fixtures', 'client_appleauth_auth_2fa_response.json'), encoding: 'utf-8')) }
    let(:no_trusted_devices_response) { JSON.parse(File.read(File.join('spaceship', 'spec', 'fixtures', 'appleauth_2fa_no_trusted_devices.json'), encoding: 'utf-8')) }
    let(:no_trusted_devices_voice_response) { JSON.parse(File.read(File.join('spaceship', 'spec', 'fixtures', 'appleauth_2fa_voice_no_trusted_devices.json'), encoding: 'utf-8')) }
    let(:no_trusted_devices_two_numbers_response) { JSON.parse(File.read(File.join('spaceship', 'spec', 'fixtures', 'appleauth_2fa_no_trusted_devices_two_numbers.json'), encoding: 'utf-8')) }

    context 'when running non-interactive' do
      it 'raises an error' do
        ENV["FASTLANE_IS_INTERACTIVE"] = "false"
        expect(subject).to receive(:handle_two_factor)
        stub_request(:get, "https://idmsa.apple.com/appleauth/auth").to_return(status: 200, body: '{"trustedPhoneNumbers": [{"1": ""}]}', headers: { 'Content-Type' => 'application/json' })
        subject.handle_two_step_or_factor("response")
      end
    end

    context 'when running non-interactive and force 2FA to be interactive only' do
      it 'raises an error' do
        ENV["FASTLANE_IS_INTERACTIVE"] = "false"
        ENV["SPACESHIP_ONLY_ALLOW_INTERACTIVE_2FA"] = "true"
        expect { subject.handle_two_step_or_factor("response") }.to raise_error("2FA can only be performed in interactive mode")
        ENV.delete('SPACESHIP_ONLY_ALLOW_INTERACTIVE_2FA')
      end
    end

    context 'when running interactive' do
      it 'does not raise an error' do
        ENV["FASTLANE_IS_INTERACTIVE"] = "true"
        ENV["SPACESHIP_ONLY_ALLOW_INTERACTIVE_2FA"] = "true"
        expect(subject).to receive(:handle_two_factor)
        stub_request(:get, "https://idmsa.apple.com/appleauth/auth").to_return(status: 200, body: '{"trustedPhoneNumbers": [{"1": ""}]}', headers: { 'Content-Type' => 'application/json' })
        subject.handle_two_step_or_factor("response")
      end
    end

    context 'when interactive mode is not set' do
      it 'does not raise an error' do
        ENV["FASTLANE_IS_INTERACTIVE"] = nil
        ENV["SPACESHIP_ONLY_ALLOW_INTERACTIVE_2FA"] = "false"
        expect(subject).to receive(:handle_two_factor)
        stub_request(:get, "https://idmsa.apple.com/appleauth/auth").to_return(status: 200, body: '{"trustedPhoneNumbers": [{"1": ""}]}', headers: { 'Content-Type' => 'application/json' })
        subject.handle_two_step_or_factor("response")
      end
    end

    context 'when SPACESHIP_2FA_SMS_DEFAULT_PHONE_NUMBER is not set' do
      context 'with trusted devices' do
        let(:response) do
          response = OpenStruct.new
          response.body = trusted_devices_response
          return response
        end

        it 'works with input sms' do
          expect(subject).to receive(:ask_for_2fa_code).twice.and_return('sms', '123')

          bool = subject.handle_two_factor(response)
          expect(bool).to eq(true)

          # sms should be sent despite having trusted devices
          expect(WebMock).to have_requested(:put, 'https://idmsa.apple.com/appleauth/auth/verify/phone').with(body: { phoneNumber: { id: 1 }, mode: "sms" })
          expect(WebMock).to have_requested(:post, 'https://idmsa.apple.com/appleauth/auth/verify/phone/securitycode').with(body: { securityCode: { code: "123" }, phoneNumber: { id: 1 }, mode: "sms" })
          expect(WebMock).to have_not_requested(:post, 'https://idmsa.apple.com/appleauth/auth/verify/trusteddevice/securitycode')
        end

        it 'does not request sms code, and submits code correctly' do
          bool = subject.handle_two_factor(response)
          expect(bool).to eq(true)

          expect(WebMock).to have_not_requested(:put, 'https://idmsa.apple.com/appleauth/auth/verify/phone')
          expect(WebMock).to have_not_requested(:post, 'https://idmsa.apple.com/appleauth/auth/verify/phone/securitycode')
          expect(WebMock).to have_requested(:post, 'https://idmsa.apple.com/appleauth/auth/verify/trusteddevice/securitycode').with(body: { securityCode: { code: "123" } })
        end
      end

      context 'with no trusted devices' do
        # sms fallback, will be sent automatically
        context "with exactly one phone number" do
          it "does not request sms code, and sends the correct request" do
            response = OpenStruct.new
            response.body = no_trusted_devices_response

            bool = subject.handle_two_factor(response)
            expect(bool).to eq(true)

            expect(WebMock).to have_not_requested(:put, 'https://idmsa.apple.com/appleauth/auth/verify/phone')
            expect(WebMock).to have_not_requested(:post, 'https://idmsa.apple.com/appleauth/auth/verify/trusteddevice/securitycode')
            expect(WebMock).to have_requested(:post, 'https://idmsa.apple.com/appleauth/auth/verify/phone/securitycode').with(body: { securityCode: { code: "123" }, phoneNumber: { id: 1 }, mode: "sms" })
          end

          it "does not request sms code, and sends the correct request with voice" do
            response = OpenStruct.new
            response.body = no_trusted_devices_voice_response

            bool = subject.handle_two_factor(response)
            expect(bool).to eq(true)

            expect(WebMock).to have_not_requested(:put, 'https://idmsa.apple.com/appleauth/auth/verify/phone')
            expect(WebMock).to have_not_requested(:post, 'https://idmsa.apple.com/appleauth/auth/verify/trusteddevice/securitycode')
            expect(WebMock).to have_requested(:post, 'https://idmsa.apple.com/appleauth/auth/verify/phone/securitycode').with(body: { securityCode: { code: "123" }, phoneNumber: { id: 1 }, mode: "voice" })
          end
        end

        # sms fallback, won't be sent automatically
        context 'with at least two phone numbers' do
          let(:phone_id) { 2 }
          let(:phone_number) { "+49 ••••• •••••81" }
          let(:response) do
            response = OpenStruct.new
            response.body = no_trusted_devices_two_numbers_response
            return response
          end

          before do
            allow(subject).to receive(:choose_phone_number).and_return(phone_number)
          end

          it 'prompts user to choose number' do
            expect(subject).to receive(:choose_phone_number)

            bool = subject.handle_two_factor(response)
            expect(bool).to eq(true)
          end

          it 'requests sms code, and submits code correctly' do
            bool = subject.handle_two_factor(response)
            expect(bool).to eq(true)

            expect(WebMock).to have_not_requested(:post, 'https://idmsa.apple.com/appleauth/auth/verify/trusteddevice/securitycode')
            expect(WebMock).to have_requested(:put, 'https://idmsa.apple.com/appleauth/auth/verify/phone').with(body: { phoneNumber: { id: phone_id }, mode: "sms" }).once
            expect(WebMock).to have_requested(:post, 'https://idmsa.apple.com/appleauth/auth/verify/phone/securitycode').with(body: { securityCode: { code: "123" }, phoneNumber: { id: phone_id }, mode: "sms" })
          end
        end
      end
    end

    context 'when SPACESHIP_2FA_SMS_DEFAULT_PHONE_NUMBER is set' do
      let(:phone_number) { '+49 123 4567885' }
      let(:phone_id) { 1 }
      let(:response) do
        response = OpenStruct.new
        response.body = trusted_devices_response
        return response
      end

      before do
        ENV['SPACESHIP_2FA_SMS_DEFAULT_PHONE_NUMBER'] = phone_number
      end

      after do
        ENV.delete('SPACESHIP_2FA_SMS_DEFAULT_PHONE_NUMBER')
      end

      it 'providing a known phone number returns true (and sends the correct requests)' do
        bool = subject.handle_two_factor(response)
        expect(bool).to eq(true)

        # expected requests
        expect(WebMock).to have_requested(:put, 'https://idmsa.apple.com/appleauth/auth/verify/phone').with(body: { phoneNumber: { id: phone_id }, mode: "sms" }).once
        expect(WebMock).to have_requested(:post, 'https://idmsa.apple.com/appleauth/auth/verify/phone/securitycode').with(body: { securityCode: { code: "123" }, phoneNumber: { id: phone_id }, mode: "sms" })
        expect(WebMock).to have_requested(:get, 'https://idmsa.apple.com/appleauth/auth/2sv/trust')
      end

      it 'providing an unknown phone number throws an exception' do
        phone_number = '+49 123 4567800'
        ENV['SPACESHIP_2FA_SMS_DEFAULT_PHONE_NUMBER'] = phone_number

        expect do
          bool = subject.handle_two_factor(response)
        end.to raise_error(Spaceship::Tunes::Error)
      end

      context 'and pushMode is voice' do
        let(:phone_number) { '+49 123 4567880' }
        let(:phone_id) { 3 }

        it 'requests voice code' do
          bool = subject.handle_two_factor(response)
          expect(bool).to eq(true)

          # expected requests
          expect(WebMock).to have_requested(:put, 'https://idmsa.apple.com/appleauth/auth/verify/phone').with(body: { phoneNumber: { id: phone_id }, mode: "voice" }).once
          expect(WebMock).to have_requested(:post, 'https://idmsa.apple.com/appleauth/auth/verify/phone/securitycode').with(body: { securityCode: { code: "123" }, phoneNumber: { id: phone_id }, mode: "voice" })
          expect(WebMock).to have_requested(:get, 'https://idmsa.apple.com/appleauth/auth/2sv/trust')
        end
      end

      context 'with trusted devices' do
        # make sure sms overrides device verification when env var is set
        it 'requests sms code, and submits code correctly' do
          bool = subject.handle_two_factor(response)
          expect(bool).to eq(true)

          expect(WebMock).to have_not_requested(:post, 'https://idmsa.apple.com/appleauth/auth/verify/trusteddevice/securitycode')
          expect(WebMock).to have_requested(:put, 'https://idmsa.apple.com/appleauth/auth/verify/phone').with(body: { phoneNumber: { id: phone_id }, mode: "sms" }).once
          expect(WebMock).to have_requested(:post, 'https://idmsa.apple.com/appleauth/auth/verify/phone/securitycode').with(body: { securityCode: { code: "123" }, phoneNumber: { id: phone_id }, mode: "sms" })
        end
      end

      context 'with no trusted devices' do
        # sms fallback, will be sent automatically
        context "with exactly one phone number" do
          it "does not request sms code, and sends the correct request" do
            response = OpenStruct.new
            response.body = no_trusted_devices_response

            bool = subject.handle_two_factor(response)
            expect(bool).to eq(true)

            expect(WebMock).to have_not_requested(:put, 'https://idmsa.apple.com/appleauth/auth/verify/phone')
            expect(WebMock).to have_not_requested(:post, 'https://idmsa.apple.com/appleauth/auth/verify/trusteddevice/securitycode')
            expect(WebMock).to have_requested(:post, 'https://idmsa.apple.com/appleauth/auth/verify/phone/securitycode').with(body: { securityCode: { code: "123" }, phoneNumber: { id: 1 }, mode: "sms" })
          end
        end

        context 'with at least two phone numbers' do
          # sets env var to the second phone number in this context
          let(:phone_number) { '+49 123 4567881' }
          let(:phone_id) { 2 }
          let(:response) do
            response = OpenStruct.new
            response.body = no_trusted_devices_two_numbers_response
            return response
          end

          # making sure we use env var for phone number selection
          it 'does not prompt user to choose number' do
            expect(subject).not_to receive(:choose_phone_number)

            bool = subject.handle_two_factor(response)
            expect(bool).to eq(true)
          end

          it 'requests sms code, and submits code correctly' do
            bool = subject.handle_two_factor(response)
            expect(bool).to eq(true)

            expect(WebMock).to have_not_requested(:post, 'https://idmsa.apple.com/appleauth/auth/verify/trusteddevice/securitycode')
            expect(WebMock).to have_requested(:put, 'https://idmsa.apple.com/appleauth/auth/verify/phone').with(body: { phoneNumber: { id: phone_id }, mode: "sms" }).once
            expect(WebMock).to have_requested(:post, 'https://idmsa.apple.com/appleauth/auth/verify/phone/securitycode').with(body: { securityCode: { code: "123" }, phoneNumber: { id: phone_id }, mode: "sms" })
          end
        end
      end
    end
  end
end
