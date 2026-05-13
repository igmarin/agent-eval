# frozen_string_literal: true

require_relative 'eval/eval_options'
require_relative 'eval/eval_commands'
require_relative 'eval/eval_command_registry'

module SkillBench
  module Cli
    # Handles the `skill-bench eval` subcommand.
    # Dispatches to appropriate command handlers.
    class EvalCommand
      # Parses argv and executes eval command.
      #
      # @param argv [Array<String>] Raw CLI arguments
      # @return [Integer] Exit code
      def self.call(argv)
        new(argv).call
      end

      # @param argv [Array<String>] Raw CLI arguments
      def initialize(argv)
        @argv = argv
      end

      # Dispatches to appropriate eval action.
      #
      def call
        action = @argv.shift
        command_class = Eval::EvalCommandRegistry.get_command(action)

        if command_class
          command_class.new.call(@argv)
        else
          warn "Unknown eval action: #{action}"
          1
        end
      end
    end
  end
end
