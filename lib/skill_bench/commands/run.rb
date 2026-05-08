# frozen_string_literal: true

require_relative '../services/runner_service'

module SkillBench
  module Commands
    # Handles the `skill-bench run` command
    class Run
      # Run an eval with specified skill
      # @param eval_name [String] Name of eval to run (e.g., 'test-eval' or 'evals/test-eval')
      # @param skill_name [String] Name of skill to use
      # @return [Hash] Result with pass/fail and score
      def self.run(eval_name:, skill_name:)
        Services::RunnerService.call(
          eval_name: eval_name,
          skill_name: skill_name
        )
      end
    end
  end
end
