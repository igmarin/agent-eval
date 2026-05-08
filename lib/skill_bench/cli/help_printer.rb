# frozen_string_literal: true

module SkillBench
  module Cli
    # Prints the CLI help/usage message.
    class HelpPrinter
      # Prints the help message and returns exit code 0.
      #
      # @return [Integer] Exit code (always 0)
      def self.call
        puts <<~USAGE
          Usage: skill-bench <subcommand> [options]

          Subcommands:
            init              Generate configuration file
            run <eval>        Run an evaluation
            skill new <name>  Create a new skill
            eval new <name>   Create a new eval

          Options:
            -h, --help        Show this help message
        USAGE
        0
      end
    end
  end
end
