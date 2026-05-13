# frozen_string_literal: true

require_relative '../../eval_generator'

module SkillBench
  module Cli
    module Eval
      # Base class for eval command handlers
      class BaseEvalCommand
        # Executes command.
        #
        # @param argv [Array<String>] Command line arguments
        # @return [Integer] Exit code
        # @raise [NotImplementedError] always — subclasses must override
        def call(argv)
          raise NotImplementedError, 'Subclasses must implement #call'
        end

        protected

        # Wraps a command block with standard rescue handling for HelpRequested
        # and generic StandardError.
        #
        # @yield Block that implements the command logic
        # @return [Integer] Exit code from the block, 0 for help, or 1 on error
        def run_with_rescue
          yield
        rescue HelpRequested
          0
        rescue StandardError => e
          warn "Error: #{e.message}"
          1
        end

        # Returns error response for missing required argument
        #
        # @param message [String] Error message
        # @return [Integer] Exit code 1
        def error_missing(message)
          warn "Error: #{message}"
          1
        end
      end

      # Handles 'eval new' command
      class NewEvalCommand < BaseEvalCommand
        # Creates a new evaluation
        #
        # @param argv [Array<String>] Command line arguments
        # @return [Integer] Exit code
        def call(argv)
          run_with_rescue do
            options_parser = NewEvalOptions.new
            options_parser.parse!(argv)

            name = argv.shift
            return error_missing('eval name is required') unless name

            Commands::EvalNew.run(name: name, **options_parser.options)
            puts "Created eval: #{name}"
            0
          end
        end
      end

      # Handles 'eval generate' command
      class GenerateEvalCommand < BaseEvalCommand
        # Generates an evaluation from a skill
        #
        # @param argv [Array<String>] Command line arguments
        # @return [Integer] Exit code
        def call(argv)
          run_with_rescue do
            options_parser = GenerateEvalOptions.new
            options_parser.parse!(argv)

            skill_name = argv.shift
            return error_missing('skill name is required') unless skill_name

            eval_name = options_parser.options[:eval_name] || "#{skill_name}-eval"
            result = EvalGenerator.new(skill_name: skill_name, eval_name: eval_name).call

            if result[:success]
              puts "Generated eval: #{eval_name} from skill: #{skill_name}"
              0
            else
              warn "Error: #{result[:response][:error][:message]}"
              1
            end
          end
        end
      end

      # Handles help display for eval commands
      class HelpEvalCommand < BaseEvalCommand
        # Shows help information
        #
        # @param _argv [Array<String>] Unused arguments
        # @return [Integer] Exit code 0
        def call(_argv)
          puts 'Usage: skill-bench eval new <name> [options]'
          puts '  --runtime TYPE  rails, ruby, etc. (default: ruby)'
          puts 'Usage: skill-bench eval generate <skill-name> [--name <eval-name>]'
          0
        end
      end
    end
  end
end
