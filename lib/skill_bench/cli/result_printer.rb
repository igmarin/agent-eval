# frozen_string_literal: true

module SkillBench
  module Cli
    # Prints the result of a `skill-bench run` command.
    class ResultPrinter
      # Prints the result and returns the appropriate exit code.
      #
      # @param result [Hash] Result from ScoringService
      # @return [Integer] Exit code (0 for pass, 1 for fail)
      def self.call(result)
        score = result[:score]
        eval_name = result[:eval_name]
        skill_name = result[:skill_name]
        provider_name = result[:provider_name]

        if result[:pass]
          puts "PASS (score: #{score})"
          puts "  eval: #{eval_name}"
          puts "  skill: #{skill_name}"
          puts "  provider: #{provider_name}"
          0
        else
          warn "FAIL (score: #{score})"
          warn "  eval: #{eval_name}"
          warn "  skill: #{skill_name}"
          warn "  provider: #{provider_name}"
          1
        end
      end
    end
  end
end
