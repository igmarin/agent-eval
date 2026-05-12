# frozen_string_literal: true

require 'optparse'

module SkillBench
  module Services
    # Parses CLI arguments for the EvaluateCommand using Ruby's OptionParser.
    # Provides standardized error handling for invalid flags and missing arguments.
    # @deprecated Use {SkillBench::Cli::RunCommand} option parsing instead.
    class OptionParserService
      # Parses command-line options into a hash.
      #
      # @param argv [Array<String>] Raw CLI arguments.
      # @return [Hash] Result envelope with parsed options or error message.
      def self.call(argv)
        new(argv).call
      end

      # @param argv [Array<String>] Raw CLI arguments.
      def initialize(argv)
        @argv = argv
      end

      # Parses the arguments and returns a result hash.
      #
      # @return [Hash] Result envelope with parsed options or error message.
      def call
        options = {}

        parser(options).parse!(@argv)

        { success: true, response: options }
      rescue OptionParser::ParseError => e
        { success: false, response: { error: { message: e.message } } }
      end

      private

      def parser(options)
        OptionParser.new do |opts|
          opts.banner = 'Usage: skill-bench [options]'

          opts.on('-e', '--eval FOLDER', 'Path to the eval folder') do |eval_path|
            options[:eval] = eval_path
          end

          opts.on('-s', '--skill FOLDER', 'Optional override for the source skill folder') do |skill_path|
            options[:skill] = skill_path
          end

          opts.on('-o', '--output FILE', 'Path to save the JSON report') do |output_path|
            options[:output] = output_path
          end

          opts.on('-h', '--help', 'Prints this help') do
            puts opts
            raise SkillBench::HelpRequested
          end
        end
      end
    end
  end
end
