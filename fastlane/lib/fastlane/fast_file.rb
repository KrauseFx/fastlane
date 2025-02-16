require "rubygems/requirement"

module Fastlane
  class FastFile
    # Stores all relevant information from the currently running process
    attr_accessor :runner

    # the platform in which we're currently in when parsing the Fastfile
    # This is used to identify the platform in which the lane is in
    attr_accessor :current_platform

    SharedValues = Fastlane::Actions::SharedValues

    # @return The runner which can be executed to trigger the given actions
    def initialize(path = nil)
      return unless (path || '').length > 0
      UI.user_error!("Could not find Fastfile at path '#{path}'") unless File.exist?(path)
      @path = File.expand_path(path)
      content = File.read(path, encoding: "utf-8")

      # From https://github.com/orta/danger/blob/master/lib/danger/Dangerfile.rb
      if content.tr!('“”‘’‛', %(""'''))
        UI.error("Your #{File.basename(path)} has had smart quotes sanitised. " \
                'To avoid issues in the future, you should not use ' \
                'TextEdit for editing it. If you are not using TextEdit, ' \
                'you should turn off smart quotes in your editor of choice.')
      end

      content.scan(/^\s*require ["'](.*?)["']/).each do |current|
        gem_name = current.last
        next if gem_name.include?(".") # these are local gems

        begin
          require(gem_name)
        rescue LoadError
          UI.important("You have required a gem, if this is a third party gem, please use `fastlane_require '#{gem_name}'` to ensure the gem is installed locally.")
        end
      end

      parse(content, @path)
    end

    def parsing_binding
      binding
    end

    def parse(data, path = nil)
      @runner ||= Runner.new

      Dir.chdir(FastlaneCore::FastlaneFolder.path || Dir.pwd) do # context: fastlane subfolder
        # create nice path that we want to print in case of some problem
        relative_path = path.nil? ? '(eval)' : Pathname.new(path).relative_path_from(Pathname.new(Dir.pwd)).to_s

        begin
          # We have to use #get_binding method, because some test files defines method called `path` (for example SwitcherFastfile)
          # and local variable has higher priority, so it causes to remove content of original Fastfile for example. With #get_binding
          # is this always clear and safe to declare any local variables we want, because the eval function uses the instance scope
          # instead of local.

          # rubocop:disable Security/Eval
          eval(data, parsing_binding, relative_path) # using eval is ok for this case
          # rubocop:enable Security/Eval
        rescue SyntaxError => ex
          match = ex.to_s.match(/#{Regexp.escape(relative_path)}:(\d+)/)
          if match
            line = match[1]
            UI.content_error(data, line)
            UI.user_error!("Syntax error in your Fastfile on line #{line}: #{ex}")
          else
            UI.user_error!("Syntax error in your Fastfile: #{ex}")
          end
        end
      end

      self
    end

    #####################################################
    # @!group DSL
    #####################################################

    # User defines a new lane
    def lane(lane_name, &block)
      UI.user_error!("You have to pass a block using 'do' for lane '#{lane_name}'. Make sure you read the docs on GitHub.") unless block

      self.runner.add_lane(Lane.new(platform: self.current_platform,
                                       block: block,
                                 description: desc_collection,
                                        name: lane_name,
                                  is_private: false))

      @desc_collection = nil # reset the collected description again for the next lane
    end

    # User defines a new private lane, which can't be called from the CLI
    def private_lane(lane_name, &block)
      UI.user_error!("You have to pass a block using 'do' for lane '#{lane_name}'. Make sure you read the docs on GitHub.") unless block

      self.runner.add_lane(Lane.new(platform: self.current_platform,
                                       block: block,
                                 description: desc_collection,
                                        name: lane_name,
                                  is_private: true))

      @desc_collection = nil # reset the collected description again for the next lane
    end

    # User defines a lane that can overwrite existing lanes. Useful when importing a Fastfile
    def override_lane(lane_name, &block)
      UI.user_error!("You have to pass a block using 'do' for lane '#{lane_name}'. Make sure you read the docs on GitHub.") unless block

      self.runner.add_lane(Lane.new(platform: self.current_platform,
                                       block: block,
                                 description: desc_collection,
                                        name: lane_name,
                                  is_private: false), true)

      @desc_collection = nil # reset the collected description again for the next lane
    end

    # User defines a platform block
    def platform(platform_name)
      SupportedPlatforms.verify!(platform_name)

      self.current_platform = platform_name

      yield

      self.current_platform = nil
    end

    # Is executed before each test run
    def before_all(&block)
      @runner.set_before_all(@current_platform, block)
    end

    # Is executed before each lane
    def before_each(&block)
      @runner.set_before_each(@current_platform, block)
    end

    # Is executed after each test run
    def after_all(&block)
      @runner.set_after_all(@current_platform, block)
    end

    # Is executed before each lane
    def after_each(&block)
      @runner.set_after_each(@current_platform, block)
    end

    # Is executed if an error occurred during fastlane execution
    def error(&block)
      @runner.set_error(@current_platform, block)
    end

    # Is used to look if the method is implemented as an action
    def method_missing(method_sym, *arguments, &_block)
      self.runner.trigger_action_by_name(method_sym, nil, false, *arguments)
    end

    #####################################################
    # @!group Other things
    #####################################################

    # Is the given key a platform block or a lane?
    def is_platform_block?(key)
      UI.crash!('No key given') unless key

      return false if self.runner.lanes.fetch(nil, {}).fetch(key.to_sym, nil)
      return true if self.runner.lanes[key.to_sym].kind_of?(Hash)

      if key.to_sym == :update
        # The user ran `fastlane update`, instead of `fastlane update_fastlane`
        # We're gonna be nice and understand what the user is trying to do
        require 'fastlane/one_off'
        Fastlane::OneOff.run(action: "update_fastlane", parameters: {})
      else
        UI.user_error!("Could not find '#{key}'. Available lanes: #{self.runner.available_lanes.join(', ')}")
      end
    end

    def actions_path(path)
      UI.crash!("Path '#{path}' not found!") unless File.directory?(path)

      Actions.load_external_actions(path)
    end

    # Execute shell command
    # Accepts arguments with and without the command named keyword so that sh
    # behaves like other actions with named keywords
    # https://github.com/fastlane/fastlane/issues/14930
    #
    # Example:
    #  sh("ls")
    #  sh("ls", log: false)
    #  sh(command: "ls")
    #  sh(command: "ls", step_name: "listing the files")
    #  sh(command: "ls", log: false)
    def sh(*args, &b)
      # First accepts hash (or named keywords) like other actions
      # Otherwise uses sh method that doesn't have an interface like an action
      if args.count == 1 && args.first.kind_of?(Hash)
        options = args.first
        command = options.delete(:command)

        raise ArgumentError, "sh requires :command keyword in argument" if command.nil?
        log = options[:log].nil? ? true : options[:log]
        FastFile.sh(*command, step_name: options[:step_name], log: log, error_callback: options[:error_callback], &b)
      elsif args.count != 1 && args.last.kind_of?(Hash)
        new_args = args.dup
        options = new_args.pop
        log = options[:log].nil? ? true : options[:log]
        FastFile.sh(*new_args, step_name: options[:step_name], log: log, error_callback: options[:error_callback], &b)
      else
        FastFile.sh(*args, &b)
      end
    end

    def self.sh(*command, step_name: nil, log: true, error_callback: nil, &b)
      command_header = step_name
      command_header ||= log ? Actions.shell_command_from_args(*command) : "shell command"

      Actions.execute_action(command_header) do
        Actions.sh_no_action(*command, log: log, error_callback: error_callback, &b)
      end
    end

    def desc(string)
      desc_collection << string
    end

    def desc_collection
      @desc_collection ||= []
    end

    def fastlane_require(gem_name)
      FastlaneRequire.install_gem_if_needed(gem_name: gem_name, require_gem: true)
    end

    def generated_fastfile_id(id)
      UI.important("The `generated_fastfile_id` action was deprecated, you can remove the line from your `Fastfile`")
    end

    def import(path = nil)
      UI.user_error!("Please pass a path to the `import` action") unless path

      path = path.dup.gsub("~", Dir.home)
      unless Pathname.new(path).absolute? # unless an absolute path
        path = File.join(File.expand_path('..', @path), path)
      end

      UI.user_error!("Could not find Fastfile at path '#{path}'") unless File.exist?(path)

      # First check if there are local actions to import in the same directory as the Fastfile
      actions_path = File.join(File.expand_path("..", path), 'actions')
      Fastlane::Actions.load_external_actions(actions_path) if File.directory?(actions_path)

      action_launched('import')

      return_value = parse(File.read(path), path)

      action_completed('import', status: FastlaneCore::ActionCompletionStatus::SUCCESS)

      return return_value
    end

    def find_tag(folder: nil, version: nil, remote: false)
      req = Gem::Requirement.new(version)
      all_tags = get_tags(folder: folder, remote: remote)

      return all_tags.select { |t| req =~ FastlaneCore::TagVersion.new(t) }.last
    end

    # @param url [String] The git URL to clone the repository from
    # @param branch [String] The branch to checkout in the repository
    # @param path [String] The path to the Fastfile
    # @param version [String, Array] Version requirement for repo tags
    # @param dependencies [Array] An optional array of additional Fastfiles in the repository
    # @param cache_path [String] An optional path to a directory where the repository should be cloned into
    # @param git_extra_headers [Array] An optional array of custom HTTP headers to access the git repo (`Authorization: Basic <YOUR BASE64 KEY>`, `Cache-Control: no-cache`, etc.)
    def import_from_git(url: nil, branch: 'HEAD', path: 'fastlane/Fastfile', version: nil, dependencies: [], cache_path: nil, git_extra_headers: []) # rubocop:disable Metrics/PerceivedComplexity
      UI.user_error!("Please pass a path to the `import_from_git` action") if url.to_s.length == 0

      Actions.execute_action('import_from_git') do
        require 'tmpdir'

        action_launched('import_from_git')

        is_eligible_for_caching = !cache_path.nil?

        UI.message("Eligible for caching") if is_eligible_for_caching

        # Checkout the repo
        repo_name = url.split("/").last
        checkout_param = branch

        import_block = proc do |target_path|
          clone_folder = File.join(target_path, repo_name)

          checkout_dependencies = dependencies.map(&:shellescape).join(" ")

          # If the current call is eligible for caching, we check out all the
          # files and directories. If not, we only check out the specified
          # `path` and `dependencies`.
          checkout_path = is_eligible_for_caching ? "" : "#{path.shellescape} #{checkout_dependencies}"

          if Dir[clone_folder].empty?
            UI.message("Cloning remote git repo...")
            Helper.with_env_values('GIT_TERMINAL_PROMPT' => '0') do
              command = ['git', 'clone', url, clone_folder, '--no-checkout']
              # When using cached clones, we need the entire repository history
              # so we can switch between tags or branches instantly, or else,
              # it would defeat the caching's purpose.
              command += ['--depth', '1'] unless is_eligible_for_caching
              command += ['--branch', branch] unless branch == 'HEAD'
              git_extra_headers.each do |header|
                command += ['--config', "http.extraHeader=#{header}"]
              end
              Actions.sh(*command)
            end
          end

          unless version.nil?
            if is_eligible_for_caching
              checkout_param = find_tag(folder: clone_folder, version: version, remote: false)

              if checkout_param.nil?
                # Update the repo and try again before failing
                UI.message("Updating git repo...")
                Helper.with_env_values('GIT_TERMINAL_PROMPT' => '0') do
                  Actions.sh("cd #{clone_folder.shellescape} && git checkout #{branch} && git reset --hard && git pull --all")
                end

                checkout_param = find_tag(folder: clone_folder, version: version, remote: false)
              else
                UI.message("Found tag #{checkout_param}. No git repo update needed.")
              end
            else
              checkout_param = find_tag(folder: clone_folder, version: version, remote: true)
            end

            UI.user_error!("No tag found matching #{version.inspect}") if checkout_param.nil?
          end

          if is_eligible_for_caching
            if version.nil?
              # Update the repo if it's eligible for caching but the version isn't specified
              UI.message("Fetching remote git branches and updating git repo...")
              Helper.with_env_values('GIT_TERMINAL_PROMPT' => '0') do
                command = "cd #{clone_folder.shellescape} && git fetch --all --quiet && git checkout #{checkout_param.shellescape} #{checkout_path} && git reset --hard"
                # Check if checked out "branch" is actually a branch or a tag
                current_branch = Actions.sh("cd #{clone_folder.shellescape} && git rev-parse --abbrev-ref HEAD")
                command << " && git rebase" unless current_branch.strip.eql?("HEAD")
                Actions.sh(command)
              end
            else
              begin
                is_checked_out = Actions.sh("cd #{clone_folder.shellescape} && git diff --name-only #{version}").strip.empty?
              rescue
                is_checked_out = false
              end

              begin
                # https://stackoverflow.com/a/1593574/865175
                current_tag = Actions.sh("cd #{clone_folder.shellescape} && git describe --exact-match --tags HEAD").strip
              rescue
                current_tag = nil
              end

              if !is_checked_out || current_tag != version
                Actions.sh("cd #{clone_folder.shellescape} && git checkout #{checkout_param.shellescape} #{checkout_path}")
              end
            end
          else
            Actions.sh("cd #{clone_folder.shellescape} && git checkout #{checkout_param.shellescape} #{checkout_path}")
          end

          # Knowing that we check out all the files and directories when the
          # current call is eligible for caching, we don't need to also
          # explicitly check out the "actions" directory.
          unless is_eligible_for_caching
            # We also want to check out all the local actions of this fastlane setup
            containing = path.split(File::SEPARATOR)[0..-2]
            containing = "." if containing.count == 0
            actions_folder = File.join(containing, "actions")
            begin
              Actions.sh("cd #{clone_folder.shellescape} && git checkout #{checkout_param.shellescape} #{actions_folder.shellescape}")
            rescue
              # We don't care about a failure here, as local actions are optional
            end
          end

          return_value = nil
          if dependencies.any?
            return_value = [import(File.join(clone_folder, path))]
            return_value += dependencies.map { |file_path| import(File.join(clone_folder, file_path)) }
          else
            return_value = import(File.join(clone_folder, path))
          end

          action_completed('import_from_git', status: FastlaneCore::ActionCompletionStatus::SUCCESS)

          return return_value
        end

        if is_eligible_for_caching
          import_block.call(File.expand_path(cache_path))
        else
          Dir.mktmpdir("fl_clone", &import_block)
        end
      end
    end

    #####################################################
    # @!group Versioning helpers
    #####################################################

    def get_tags(folder: nil, remote: false)
      if remote
        UI.message("Fetching remote git tags...")
        Helper.with_env_values('GIT_TERMINAL_PROMPT' => '0') do
          Actions.sh("cd #{folder.shellescape} && git fetch --all --tags -q")
        end
      end

      # Fetch all possible tags
      git_tags_string = Actions.sh("cd #{folder.shellescape} && git tag -l")
      git_tags = git_tags_string.split("\n")

      # Sort tags based on their version number
      return git_tags
             .select { |tag| FastlaneCore::TagVersion.correct?(tag) }
             .sort_by { |tag| FastlaneCore::TagVersion.new(tag) }
    end

    #####################################################
    # @!group Overwriting Ruby methods
    #####################################################

    # Speak out loud
    def say(value)
      # Overwrite this, since there is already a 'say' method defined in the Ruby standard library
      value ||= yield

      value = { text: value } if value.kind_of?(String) || value.kind_of?(Array)
      self.runner.trigger_action_by_name(:say, nil, false, value)
    end

    def puts(value)
      # Overwrite this, since there is already a 'puts' method defined in the Ruby standard library
      value ||= yield if block_given?

      action_launched('puts')
      return_value = Fastlane::Actions::PutsAction.run([value])
      action_completed('puts', status: FastlaneCore::ActionCompletionStatus::SUCCESS)
      return return_value
    end

    def test(params = {})
      # Overwrite this, since there is already a 'test' method defined in the Ruby standard library
      self.runner.try_switch_to_lane(:test, [params])
    end

    def action_launched(action_name)
      action_launch_context = FastlaneCore::ActionLaunchContext.context_for_action_name(action_name,
                                                                                        fastlane_client_language: :ruby,
                                                                                        args: ARGV)
      FastlaneCore.session.action_launched(launch_context: action_launch_context)
    end

    def action_completed(action_name, status: nil)
      completion_context = FastlaneCore::ActionCompletionContext.context_for_action_name(action_name,
                                                                                         args: ARGV,
                                                                                         status: status)
      FastlaneCore.session.action_completed(completion_context: completion_context)
    end
  end
end
