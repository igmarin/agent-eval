# frozen_string_literal: true

module SkillBench
  module Cli
    module Eval
      # Registry for eval command handlers
      class EvalCommandRegistry
        # Maps action names to command classes
        COMMANDS = {
          'new' => NewEvalCommand,
          'generate' => GenerateEvalCommand,
          'help' => HelpEvalCommand
        }.freeze

        # Gets command class for action
        #
        # @param action [String] Command action name
        # @return [Class<BaseEvalCommand>, nil] Command class or nil if not found
        def self.get_command(action)
          return COMMANDS['help'] if action.nil? || action.match?(/^(-h|--help|help)$/)

          COMMANDS[action]
        end

        # Lists all available actions
        #
        # @return [Array<String>] Available action names
        def self.available_actions
          COMMANDS.keys
        end
      end
    end
  end
end
