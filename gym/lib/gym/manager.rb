require 'fastlane_core/print_table'
require_relative 'module'
require_relative 'runner'

module Gym
  class Manager
    def initialize
      @runner = Runner.new
    end

    def work(options)
      Gym.config = options

      # Also print out the path to the used Xcode installation
      # We go 2 folders up, to not show "Contents/Developer/"
      values = Gym.config.values(ask: false)
      values[:xcode_path] = File.expand_path("../..", FastlaneCore::Helper.xcode_path)

      FastlaneCore::PrintTable.print_values(config: values,
                                         hide_keys: [],
                                             title: "Summary for gym #{Fastlane::VERSION}")

      return @runner.run
    end

    def build_time
      @runner.build_time
    end
  end
end
