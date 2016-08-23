module Snapshot
  class LatestOsVersion
    def self.ios_version
      return ENV["SNAPSHOT_IOS_VERSION"] if ENV["SNAPSHOT_IOS_VERSION"]
      self.version("iOS")
    end

    @versions = {}
    def self.version(os)
      @versions[os] ||= version_for_os(os)
    end

    def self.version_for_os(os)
      # We do all this, because we would get all kind of crap output generated by xcodebuild
      # so we need to ignore stderror
      output = ''
      Open3.popen3('xcodebuild -version -sdk') do |stdin, stdout, stderr, wait_thr|
        output = stdout.read
      end

      matched = output.match(/#{os} ([\d\.]+) \(.*/)
      if matched.nil?
        UI.user_error!("Could not determine installed #{os} SDK version. Try running the _xcodebuild_ command manually to ensure it works.")
      elsif matched.length > 1
        return matched[1]
      else
        UI.user_error!("Could not determine installed #{os} SDK version. Please pass it via the environment variable 'SNAPSHOT_IOS_VERSION'")
      end
    end
  end
end
