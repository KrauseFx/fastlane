require 'tempfile'
require 'openssl'

require_relative 'features'
require_relative 'helper'

# WWDR Intermediate Certificates in https://www.apple.com/certificateauthority/
WWDRCA_CERTIFICATES = [
  {
    alias: 'G2',
    sha256: '9ed4b3b88c6a339cf1387895bda9ca6ea31a6b5ce9edf7511845923b0c8ac94c',
    url: 'https://www.apple.com/certificateauthority/AppleWWDRCAG2.cer'
  },
  {
    alias: 'G3',
    sha256: 'dcf21878c77f4198e4b4614f03d696d89c66c66008d4244e1b99161aac91601f',
    url: 'https://www.apple.com/certificateauthority/AppleWWDRCAG3.cer'
  },
  {
    alias: 'G4',
    sha256: 'ea4757885538dd8cb59ff4556f676087d83c85e70902c122e42c0808b5bce14c',
    url: 'https://www.apple.com/certificateauthority/AppleWWDRCAG4.cer'
  },
  {
    alias: 'G5',
    sha256: '53fd008278e5a595fe1e908ae9c5e5675f26243264a5a6438c023e3ce2870760',
    url: 'https://www.apple.com/certificateauthority/AppleWWDRCAG5.cer'
  },
  {
    alias: 'G6',
    sha256: 'bdd4ed6e74691f0c2bfd01be0296197af1379e0418e2d300efa9c3bef642ca30',
    url: 'https://www.apple.com/certificateauthority/AppleWWDRCAG6.cer'
  },
  {
    alias: 'DEV-ID-G1',
    sha256: '7afc9d01a62f03a2de9637936d4afe68090d2de18d03f29c88cfb0b1ba63587f',
    url: 'https://www.apple.com/certificateauthority/DeveloperIDCA.cer'
  },
  {
    alias: 'DEV-ID-G2',
    sha256: 'f16cd3c54c7f83cea4bf1a3e6a0819c8aaa8e4a1528fd144715f350643d2df3a',
    url: 'https://www.apple.com/certificateauthority/DeveloperIDG2CA.cer'
  }
]

module FastlaneCore
  # This class checks if a specific certificate is installed on the current mac
  class CertChecker
    def self.installed?(path, in_keychain: nil)
      UI.user_error!("Could not find file '#{path}'") unless File.exist?(path)

      ids = installed_identities(in_keychain: in_keychain)
      ids += installed_installers(in_keychain: in_keychain)
      finger_print = sha1_fingerprint(path)

      return ids.include?(finger_print)
    end

    # Legacy Method, use `installed?` instead
    def self.is_installed?(path)
      installed?(path)
    end

    def self.installed_identities(in_keychain: nil)
      install_missing_wwdr_certificates

      available = list_available_identities(in_keychain: in_keychain)
      # Match for this text against word boundaries to avoid edge cases around multiples of 10 identities!
      if /\b0 valid identities found\b/ =~ available
        UI.error([
          "There are no local code signing identities found.",
          "You can run" << " `security find-identity -v -p codesigning #{in_keychain}".rstrip << "` to get this output.",
          "This Stack Overflow thread has more information: https://stackoverflow.com/q/35390072/774.",
          "(Check in Keychain Access for an expired WWDR certificate: https://stackoverflow.com/a/35409835/774 has more info.)"
        ].join("\n"))
      end

      ids = []
      available.split("\n").each do |current|
        next if current.include?("REVOKED")
        begin
          (ids << current.match(/.*\) ([[:xdigit:]]*) \".*/)[1])
        rescue
          # the last line does not match
        end
      end

      return ids
    end

    def self.installed_installers(in_keychain: nil)
      available = self.list_available_third_party_mac_installer(in_keychain: in_keychain)
      available += self.list_available_developer_id_installer(in_keychain: in_keychain)

      return available.scan(/^SHA-1 hash: ([[:xdigit:]]+)$/).flatten
    end

    def self.list_available_identities(in_keychain: nil)
      # -v  Show valid identities only (default is to show all identities)
      # -p  Specify policy to evaluate
      commands = ['security find-identity -v -p codesigning']
      commands << in_keychain if in_keychain
      `#{commands.join(' ')}`
    end

    def self.list_available_third_party_mac_installer(in_keychain: nil)
      # -Z  Print SHA-256 (and SHA-1) hash of the certificate
      # -a  Find all matching certificates, not just the first one
      # -c  Match on "name" when searching (optional)
      commands = ['security find-certificate -Z -a -c "3rd Party Mac Developer Installer"']
      commands << in_keychain if in_keychain
      `#{commands.join(' ')}`
    end

    def self.list_available_developer_id_installer(in_keychain: nil)
      # -Z  Print SHA-256 (and SHA-1) hash of the certificate
      # -a  Find all matching certificates, not just the first one
      # -c  Match on "name" when searching (optional)
      commands = ['security find-certificate -Z -a -c "Developer ID Installer"']
      commands << in_keychain if in_keychain
      `#{commands.join(' ')}`
    end

    def self.installed_wwdr_certificates
      certificate_name = "Apple Worldwide Developer Relations"

      # Find all installed WWDRCA certificates
      installed_certs = []
      Helper.backticks("security find-certificate -a -c '#{certificate_name}' -p #{wwdr_keychain.shellescape}", print: false)
            .lines
            .each do |line|
        if line.start_with?('-----BEGIN CERTIFICATE-----')
          installed_certs << line
        else
          installed_certs.last << line
        end
      end

      # Get the alias (see `WWDRCA_CERTIFICATES`) of the installed WWDRCA certificates
      installed_certs
        .map do |pem|
          sha256 = Digest::SHA256.hexdigest(OpenSSL::X509::Certificate.new(pem).to_der)
          WWDRCA_CERTIFICATES.find { |c| c[:sha256].casecmp?(sha256) }&.fetch(:alias)
        end
        .compact
    end

    def self.install_missing_wwdr_certificates
      # Install all Worldwide Developer Relations Intermediate Certificates listed here: https://www.apple.com/certificateauthority/
      missing = WWDRCA_CERTIFICATES.map { |c| c[:alias] } - installed_wwdr_certificates
      missing.each do |cert_alias|
        install_wwdr_certificate(cert_alias)
      end
      missing.count
    end

    def self.install_wwdr_certificate(cert_alias)
      url = WWDRCA_CERTIFICATES.find { |c| c[:alias] == cert_alias }.fetch(:url)
      file = Tempfile.new([File.basename(url, ".cer"), ".cer"])
      filename = file.path
      keychain = wwdr_keychain
      keychain = "-k #{keychain.shellescape}" unless keychain.empty?

      # Attempts to fix an issue installing WWDR cert tends to fail on CIs
      # https://github.com/fastlane/fastlane/issues/20960
      curl_extras = ""
      if FastlaneCore::Feature.enabled?('FASTLANE_WWDR_USE_HTTP1_AND_RETRIES')
        curl_extras = "--http1.1 --retry 3 --retry-all-errors "
      end

      import_command = "curl #{curl_extras}-f -o #{filename} #{url} && security import #{filename} #{keychain}"
      UI.verbose("Installing WWDR Cert: #{import_command}")

      require 'open3'
      stdout, stderr, status = Open3.capture3(import_command)
      if FastlaneCore::Globals.verbose?
        UI.command_output(stdout)
        UI.command_output(stderr)
      end

      unless status.success?
        UI.verbose("Failed to install WWDR Certificate, checking output to see why")
        # Check the command output, WWDR might already exist
        unless /The specified item already exists in the keychain./ =~ stderr
          UI.user_error!("Could not install WWDR certificate")
        end
        UI.verbose("WWDR Certificate was already installed")
      end
      return true
    end

    def self.wwdr_keychain
      priority = [
        "security default-keychain -d user",
        "security list-keychains -d user"
      ]
      priority.each do |command|
        keychains = Helper.backticks(command, print: FastlaneCore::Globals.verbose?).split("\n")
        unless keychains.empty?
          # Select first keychain name from returned keychains list
          return keychains[0].strip.tr('"', '')
        end
      end
      return ""
    end

    def self.sha1_fingerprint(path)
      file_data = File.read(path.to_s)
      cert = OpenSSL::X509::Certificate.new(file_data)
      return OpenSSL::Digest::SHA1.new(cert.to_der).to_s.upcase
    rescue => error
      UI.error(error)
      UI.user_error!("Error parsing certificate '#{path}'")
    end
  end
end
