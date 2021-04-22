module Fastlane
  # Alert the user when updates for plugins are available
  class PluginUpdateManager
    def self.start_looking_for_updates
      return if Helper.test?
      return if FastlaneCore::Env.truthy?("FASTLANE_SKIP_UPDATE_CHECK")

      Thread.new do
        self.plugin_references.each do |plugin_name, current_plugin|
          begin
            self.server_results[plugin_name] = fetch_latest_version(plugin_name)
          rescue
          end
        end
      end
    end

    def self.show_update_status
      return if FastlaneCore::Env.truthy?("FASTLANE_SKIP_UPDATE_CHECK")

      # We set self.server_results to be nil
      # this way the table is not printed twice
      # (next to the summary table or when an exception happens)
      return unless self.server_results.count > 0

      rows = []
      self.plugin_references.each do |plugin_name, current_plugin|
        latest_version = self.server_results[plugin_name]
        next if latest_version.nil?
        current_version = Gem::Version.new(current_plugin[:version_number])
        next if current_version >= latest_version

        rows << [
          plugin_name.gsub(PluginManager.plugin_prefix, ''),
          current_version.to_s.red,
          latest_version.to_s.green
        ]
      end

      if rows.empty?
        UI.verbose("All plugins are up to date")
        return
      end

      require 'terminal-table'
      puts(Terminal::Table.new({
        rows: FastlaneCore::PrintTable.transform_output(rows),
        title: "Plugin updates available".yellow,
        headings: ["Plugin", "Your Version", "Latest Version"]
      }))
      UI.message("To update all plugins, just run")
      UI.command "bundle exec fastlane update_plugins"
      puts('')
      @server_results = nil
    end

    def self.plugin_references
      Fastlane.plugin_manager.plugin_references
    end

    def self.fetch_latest_version(gem_name)
      Gem::Version.new(PluginManager.fetch_gem_info_from_rubygems(gem_name)["version"])
    rescue
      nil
    end

    def self.server_results
      @server_results ||= {}
    end
  end
end
