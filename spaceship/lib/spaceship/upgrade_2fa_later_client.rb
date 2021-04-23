require_relative 'globals'
require_relative 'tunes/tunes_client'

module Spaceship
  class Client
    def try_upgrade_2fa_later(response)
      if ENV['SPACESHIP_SKIP_2FA_UPGRADE'].nil?
        return false
      end

      puts("This account is being prompted to upgrade to 2FA")
      puts("Attempting to automatically bypass the upgrade until a later date")
      puts("To disable this, remove SPACESHIP_SKIP_2FA_UPGRADE=1 environment variable")

      # Get URL that requests a repair and gets the widget key
      widget_key_location = response.headers['location']
      uri    = URI.parse(widget_key_location)
      params = CGI.parse(uri.query)

      widget_key = params.dig('widgetKey', 0)
      if widget_key.nil?
        warn("Couldn't find widgetKey to continue with requests")
        return false
      end

      # Step 1 - Request repair
      response_repair = request(:get) do |req|
        req.url(widget_key_location)
      end

      # Step 2 - Request repair options
      response_repair_options = request(:get) do |req|
        req.url("https://appleid.apple.com/account/manage/repair/options")

        req.headers['scnt'] = response_repair.headers['scnt']
        req.headers['X-Apple-Id-Session-Id'] = response.headers['X-Apple-Id-Session-Id']
        req.headers['X-Apple-Session-Token'] = response.headers['X-Apple-Repair-Session-Token']

        req.headers['X-Apple-Skip-Repair-Attributes'] = '[]'
        req.headers['X-Apple-Widget-Key'] = widget_key

        req.headers['Content-Type'] = 'application/json'
        req.headers['X-Requested-With'] = 'XMLHttpRequest'
        req.headers['Accept'] = 'application/json, text/javascript'
      end

      # Step 3 - Request setup later
      request(:get) do |req|
        req.url("https://appleid.apple.com/account/security/upgrade/setuplater")

        req.headers['scnt'] = response_repair_options.headers['scnt']
        req.headers['X-Apple-Id-Session-Id'] = response.headers['X-Apple-Id-Session-Id']
        req.headers['X-Apple-Session-Token'] = response_repair_options.headers['x-apple-session-token']
        req.headers['X-Apple-Skip-Repair-Attributes'] = '[]'
        req.headers['X-Apple-Widget-Key'] = widget_key

        req.headers['Content-Type'] = 'application/json'
        req.headers['X-Requested-With'] = 'XMLHttpRequest'
        req.headers['Accept'] = 'application/json, text/javascript'
      end

      # Step 4 - Post complete
      response_repair_complete = request(:post) do |req|
        req.url("https://idmsa.apple.com/appleauth/auth/repair/complete")

        req.body = ''
        req.headers['scnt'] = response.headers['scnt']
        req.headers['X-Apple-Id-Session-Id'] = response.headers['X-Apple-Id-Session-Id']
        req.headers['X-Apple-Repair-Session-Token'] = response_repair_options.headers['X-Apple-Session-Token']

        req.headers['X-Apple-Widget-Key'] = widget_key

        req.headers['Content-Type'] = 'application/json'
        req.headers['X-Requested-With'] = 'XMLHttpRequest'
        req.headers['Accept'] = 'application/json;charset=utf-8'
      end

      if response_repair_complete.status == 204
        return true
      else
        warn("Failed with status code of #{response_repair_complete.status}")
        return false
      end
    rescue => error
      warn(error.backtrace)
      warn("Failed to bypass 2FA upgrade")
      warn("To disable this from trying again, set SPACESHIP_SKIP_UPGRADE_2FA_LATER=1")
      return false
    end
  end
end
