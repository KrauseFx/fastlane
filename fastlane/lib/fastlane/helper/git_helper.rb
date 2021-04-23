module Fastlane
  module Actions
    GIT_MERGE_COMMIT_FILTERING_OPTIONS = [:include_merges, :exclude_merges, :only_include_merges].freeze

    module SharedValues
      GIT_BRANCH_ENV_VARS = %w(GIT_BRANCH BRANCH_NAME TRAVIS_BRANCH BITRISE_GIT_BRANCH CI_BUILD_REF_NAME CI_COMMIT_REF_NAME WERCKER_GIT_BRANCH BUILDKITE_BRANCH APPCENTER_BRANCH CIRCLE_BRANCH).reject do |branch|
        # Removing because tests break on CircleCI
        Helper.test? && branch == "CIRCLE_BRANCH"
      end.freeze
    end

    def self.git_log_between(pretty_format, from, to, merge_commit_filtering, date_format = nil, ancestry_path)
      command = %w(git log)
      command << "--pretty=#{pretty_format}"
      command << "--date=#{date_format}" if date_format
      command << '--ancestry-path' if ancestry_path
      command << "#{from}...#{to}"
      command << git_log_merge_commit_filtering_option(merge_commit_filtering)
      # "*command" syntax expands "command" array into variable arguments, which
      # will then be individually shell-escaped by Actions.sh.
      Actions.sh(*command.compact, log: false).chomp
    rescue
      nil
    end

    def self.git_log_last_commits(pretty_format, commit_count, merge_commit_filtering, date_format = nil, ancestry_path)
      command = %w(git log)
      command << "--pretty=#{pretty_format}"
      command << "--date=#{date_format}" if date_format
      command << '--ancestry-path' if ancestry_path
      command << '-n' << commit_count.to_s
      command << git_log_merge_commit_filtering_option(merge_commit_filtering)
      Actions.sh(*command.compact, log: false).chomp
    rescue
      nil
    end

    def self.last_git_tag_hash(tag_match_pattern = nil)
      tag_pattern_param = tag_match_pattern ? "=#{tag_match_pattern}" : ''
      Actions.sh('git', 'rev-list', "--tags#{tag_pattern_param}", '--max-count=1').chomp
    rescue
      nil
    end

    def self.last_git_tag_name(match_lightweight = true, tag_match_pattern = nil)
      hash = last_git_tag_hash(tag_match_pattern)
      # If hash is nil (command fails), "git describe" command below will still
      # run and provide some output, although it's definitely not going to be
      # anything reasonably expected. Bail out early.
      return unless hash

      command = %w(git describe)
      command << '--tags' if match_lightweight
      command << hash
      command << '--match' if tag_match_pattern
      command << tag_match_pattern if tag_match_pattern
      Actions.sh(*command.compact, log: false).chomp
    rescue
      nil
    end

    def self.last_git_commit_dict
      return nil if last_git_commit_formatted_with('%an').nil?

      {
          author: last_git_commit_formatted_with('%an'),
          author_email: last_git_commit_formatted_with('%ae'),
          message: last_git_commit_formatted_with('%B'),
          commit_hash: last_git_commit_formatted_with('%H'),
          abbreviated_commit_hash: last_git_commit_formatted_with('%h')
      }
    end

    # Gets the last git commit information formatted into a String by the provided
    # pretty format String. See the git-log documentation for valid format placeholders
    def self.last_git_commit_formatted_with(pretty_format, date_format = nil)
      command = %w(git log -1)
      command << "--pretty=#{pretty_format}"
      command << "--date=#{date_format}" if date_format
      Actions.sh(*command.compact, log: false).chomp
    rescue
      nil
    end

    # @deprecated Use <tt>git_author_email</tt> instead
    # Get the author email of the last git commit
    # <b>DEPRECATED:</b> Use <tt>git_author_email</tt> instead.
    def self.git_author
      UI.deprecated('`git_author` is deprecated. Please use `git_author_email` instead.')
      git_author_email
    end

    # Get the author email of the last git commit
    def self.git_author_email
      s = last_git_commit_formatted_with('%ae')
      return s if s.to_s.length > 0
      return nil
    end

    # Returns the unwrapped subject and body of the last commit
    # <b>DEPRECATED:</b> Use <tt>last_git_commit_message</tt> instead.
    def self.last_git_commit
      UI.important('`last_git_commit` is deprecated. Please use `last_git_commit_message` instead.')
      last_git_commit_message
    end

    # Returns the unwrapped subject and body of the last commit
    def self.last_git_commit_message
      s = (last_git_commit_formatted_with('%B') || "").strip
      return s if s.to_s.length > 0
      nil
    end

    # Get the hash of the last commit
    def self.last_git_commit_hash(short)
      format_specifier = short ? '%h' : '%H'
      string = last_git_commit_formatted_with(format_specifier).to_s
      return string unless string.empty?
      return nil
    end

    # Returns the current git branch, or "HEAD" if it's not checked out to any branch
    # Can be replaced using the environment variable `GIT_BRANCH`
    def self.git_branch
      env_name = SharedValues::GIT_BRANCH_ENV_VARS.find { |env_var| FastlaneCore::Env.truthy?(env_var) }
      ENV.fetch(env_name.to_s) do
        # Rescues if not a git repo or no commits in a git repo
        begin
          Actions.sh("git rev-parse --abbrev-ref HEAD", log: false).chomp
        rescue => err
          UI.verbose("Error getting git branch: #{err.message}")
          nil
        end
      end
    end

    def self.git_log_merge_commit_filtering_option(merge_commit_filtering)
      case merge_commit_filtering
      when :exclude_merges
        "--no-merges"
      when :only_include_merges
        "--merges"
      when :include_merges
        nil
      end
    end
  end
end
