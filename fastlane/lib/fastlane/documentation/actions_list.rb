module Fastlane
  class ActionsList
    def self.run(filter: nil, platform: nil)
      require 'terminal-table'
      if filter
        show_details(filter: filter)
      else
        print_all(platform: platform)
      end
    end

    def self.print_all(platform: nil)
      rows = []
      all_actions(platform) do |action, name|
        current = []

        if Fastlane::Actions.is_deprecated?(action)
          current << "#{name} (DEPRECATED)".deprecated
        else
          current << name.yellow
        end

        if action < Action
          current << action.description.to_s.remove_markdown if action.description

          authors = Array(action.author || action.authors)
          current << authors.first.green if authors.count == 1
          current << "Multiple".green if authors.count > 1
        else
          UI.error(action_subclass_error(name))
          current << "Please update action file".red
          current << ' '
        end
        rows << current
      end

      puts(Terminal::Table.new(
             title: "Available fastlane actions".green,
             headings: ['Action', 'Description', 'Author'],
             rows: FastlaneCore::PrintTable.transform_output(rows)
           ))
      puts("  Platform filter: #{platform}".magenta) if platform
      puts("  Total of #{rows.count} actions")

      puts("\nGet more information for one specific action using `fastlane action [name]`\n".green)
    end

    def self.show_details(filter: nil)
      puts("Loading documentation for #{filter}:".green)
      puts("")

      action = find_action_named(filter)

      if action
        unless action < Action
          UI.user_error!(action_subclass_error(filter))
        end

        print_summary(action, filter)
        print_options(action, filter)
        print_output_variables(action, filter)
        print_return_value(action, filter)

        if Fastlane::Actions.is_deprecated?(action)
          puts("==========================================".deprecated)
          puts("This action (#{filter}) is deprecated".deprecated)
          puts(action.deprecated_notes.to_s.remove_markdown.deprecated) if action.deprecated_notes
          puts("==========================================\n".deprecated)
        end

        puts("More information can be found on https://docs.fastlane.tools/actions/#{filter}")
        puts("")
      else
        puts("Couldn't find action for the given filter.".red)
        puts("==========================================\n".red)

        print_all # show all available actions instead
        print_suggestions(filter)
      end
    end

    def self.print_suggestions(filter)
      if !filter.nil? && filter.length > 1
        action_names = []
        all_actions(nil) do |action_ref, action_name|
          action_names << action_name
        end

        corrections = []

        if defined?(DidYouMean::SpellChecker)
          spell_checker = DidYouMean::SpellChecker.new(dictionary: action_names)
          corrections << spell_checker.correct(filter).compact
        end

        corrections << action_names.select { |name| name.include?(filter) }

        puts("Did you mean: #{corrections.flatten.uniq.join(', ')}?".green) unless corrections.flatten.empty?
      end
    end

    def self.action_subclass_error(name)
      "Please update your action '#{name}' to be a subclass of `Action` by adding ` < Action` after your class name."
    end

    def self.print_summary(action, name)
      rows = []

      if action.description
        description = action.description.to_s.remove_markdown
        rows << [description]
        rows << [' ']
      end

      if action.details
        details = action.details.to_s.remove_markdown
        details.split("\n").each do |detail|
          row = detail.empty? ? ' ' : detail
          rows << [row]
        end

        rows << [' ']
      end

      authors = Array(action.author || action.authors)
      rows << ["Created by #{authors.join(', ').green}"] unless authors.empty?

      puts(Terminal::Table.new(title: name.green, rows: FastlaneCore::PrintTable.transform_output(rows)))
      puts("")
    end

    def self.print_options(action, name)
      options = parse_options(action.available_options) if action.available_options

      if options
        puts(Terminal::Table.new(
               title: "#{name} Options".green,
               headings: ['Key', 'Description', 'Env Var(s)', 'Default'],
               rows: FastlaneCore::PrintTable.transform_output(options)
             ))
      else
        puts("No available options".yellow)
      end
      puts("* = default value is dependent on the user's system")
      puts("")
    end

    def self.print_output_variables(action, name)
      output = action.output
      return if output.nil? || output.empty?

      puts(Terminal::Table.new(
             title: "#{name} Output Variables".green,
             headings: ['Key', 'Description'],
             rows: FastlaneCore::PrintTable.transform_output(output.map { |key, desc| [key.yellow, desc] })
           ))
      puts("Access the output values using `lane_context[SharedValues::VARIABLE_NAME]`")
      puts("")
    end

    def self.print_return_value(action, name)
      return unless action.return_value

      puts(Terminal::Table.new(title: "#{name} Return Value".green,
                                rows: FastlaneCore::PrintTable.transform_output([[action.return_value]])))
      puts("")
    end

    # Iterates through all available actions and yields from there
    def self.all_actions(platform = nil)
      action_symbols = Fastlane::Actions.constants.select { |c| Fastlane::Actions.const_get(c).kind_of?(Class) && c != :TestSampleCodeAction }
      action_symbols.sort.each do |symbol|
        action = Fastlane::Actions.const_get(symbol)

        # We allow classes that don't respond to is_supported? to come through because we want to list
        # them as broken actions in the table, regardless of platform specification
        next if platform && action.respond_to?(:is_supported?) && !action.is_supported?(platform.to_sym)

        name = symbol.to_s.gsub(/Action$/, '').fastlane_underscore
        yield(action, name)
      end
    end

    def self.find_action_named(name)
      all_actions do |action, action_name|
        return action if action_name == name
      end

      nil
    end

    # Helper:
    def self.parse_options(options, fill_all = true)
      rows = []
      rows << [options] if options.kind_of?(String)

      if options.kind_of?(Array)
        options.each do |current|
          if current.kind_of?(FastlaneCore::ConfigItem)
            rows << [current.key.to_s.yellow, current.deprecated ? current.description.red : current.description, current.env_names.join(", "), current.help_default_value]
          elsif current.kind_of?(Array)
            # Legacy actions that don't use the new config manager
            UI.user_error!("Invalid number of elements in this row: #{current}. Must be 2 or 3") unless [2, 3].include?(current.count)
            rows << current
            rows.last[0] = rows.last.first.yellow # color it yellow :)
            rows.last << nil while fill_all && rows.last.count < 4 # to have a nice border in the table
          end
        end
      end

      rows
    end
  end
end
