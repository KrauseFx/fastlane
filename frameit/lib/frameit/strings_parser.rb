require_relative 'module'

module Frameit
  # This class will parse the .string files
  class StringsParser
    def self.parse(path)
      UI.user_error!("Couldn't find strings file at path '#{path}'") unless File.exist?(path)
      UI.user_error!("Must be .strings file, only got '#{path}'") unless path.end_with?(".strings")

      result = {}

      # A .strings file is UTF-16 encoded. We only want to deal with UTF-8
      encoding = encoding_type(path)
      if encoding.include?('utf-8') || encoding.include?('us-ascii')
        content = File.read(path)
      else
        content = `iconv -f UTF-16 -t UTF-8 "#{path}" 2>&1` # NOTE: double quotes around path so command also works on Windows
      end

      content.split("\n").each_with_index do |line, index|
        begin
          # We don't care about comments and empty lines
          if line.start_with?('"')
            key = line.match(/"(.*)" \= /)[1]
            value = line.match(/ \= "(.*)"/)[1]

            result[key] = value
          end
        rescue => ex
          UI.error("Error parsing #{path} line #{index + 1}: '#{line}'")
          UI.verbose("#{ex.message}\n#{ex.backtrace.join('\n')}")
        end
      end

      if result.empty?
        UI.error("Empty parsing result for #{path}. Please make sure the file is valid and UTF16 Big-endian encoded")
      end

      result
    end

    def self.encoding_type(path)
      Helper.backticks("file --mime-encoding #{path.shellescape}", print: false).downcase
    end
  end
end
