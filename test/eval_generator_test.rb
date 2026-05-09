# frozen_string_literal: true

require 'test_helper'

module SkillBench
  class EvalGeneratorTest < Minitest::Test
    def setup
      @tmp_dir = Dir.mktmpdir('eval_generator_test')
      @original_dir = Dir.pwd
      Dir.chdir(@tmp_dir)

      FileUtils.mkdir_p('skills/test-skill')
      File.write('skills/test-skill/SKILL.md', '# Test Skill\n\nThis skill creates service objects.')
    end

    def teardown
      Dir.chdir(@original_dir)
      FileUtils.rm_rf(@tmp_dir)
    end

    def test_generates_eval_from_skill
      generator = EvalGenerator.new(skill_name: 'test-skill', eval_name: 'test-skill-eval')

      SkillBench::Clients::ProviderRegistry.stubs(:for).returns(MockLLMClient)

      result = generator.call

      assert result[:success]
      assert_path_exists 'evals/test-skill-eval/task.md'
      assert_path_exists 'evals/test-skill-eval/criteria.json'

      criteria = JSON.parse(File.read('evals/test-skill-eval/criteria.json'))

      assert criteria['dimensions']
      assert_equal 5, criteria['dimensions'].size
      assert criteria['pass_threshold']
      assert criteria['minimum_delta']
    end

    def test_returns_error_when_skill_missing
      generator = EvalGenerator.new(skill_name: 'missing', eval_name: 'test-eval')

      result = generator.call

      refute result[:success]
      assert_match(/Skill not found/, result[:response][:error][:message])
    end

    def test_returns_error_when_eval_name_contains_path_traversal
      generator = EvalGenerator.new(skill_name: 'test-skill', eval_name: '../../../etc/cron')

      result = generator.call

      refute result[:success]
      assert_match(/Invalid eval name/, result[:response][:error][:message])
    end

    module MockLLMClient
      def self.call(_system_prompt:, messages:, **)
        messages.first[:content]
        {
          success: true,
          result: <<~JSON,
            {
              "task": "Create a service object that validates user input.",
              "context": "Evaluate service object creation skill",
              "dimensions": [
                { "name": "correctness", "max_score": 30 },
                { "name": "skill_adherence", "max_score": 25 },
                { "name": "code_quality", "max_score": 20 },
                { "name": "test_coverage", "max_score": 15 },
                { "name": "documentation", "max_score": 10 }
              ],
              "pass_threshold": 70,
              "minimum_delta": 10
            }
          JSON
          response: { choices: [{ message: { content: '{}' } }] },
          usage: {}
        }
      end
    end
  end
end
