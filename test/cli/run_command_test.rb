# frozen_string_literal: true

require 'test_helper'

module SkillBench
  module Cli
    class RunCommandTest < Minitest::Test
      def setup
        @tmp_dir = Dir.mktmpdir('cli_run_test')
        @original_dir = Dir.pwd
        Dir.chdir(@tmp_dir)

        FileUtils.mkdir_p('evals/test-eval')
        File.write('evals/test-eval/task.md', 'Test task')
        File.write('evals/test-eval/criteria.json', '{"pass": {"score_threshold": 0.8}}')

        FileUtils.mkdir_p('skills/test-skill')
        File.write('skills/test-skill/SKILL.md', 'Test skill')

        config = {
          provider: 'mock',
          max_execution_time: 30,
          config: {}
        }
        File.write('skill-bench.json', JSON.generate(config))
      end

      def teardown
        Dir.chdir(@original_dir)
        FileUtils.rm_rf(@tmp_dir)
      end

      def test_call_with_eval_and_skill
        exit_code = RunCommand.call(['test-eval', '--skill=test-skill'])

        assert_equal 0, exit_code
      end

      def test_call_with_full_path_eval
        exit_code = RunCommand.call(['evals/test-eval', '--skill=test-skill'])

        assert_equal 0, exit_code
      end

      def test_call_without_eval_returns_error
        exit_code = RunCommand.call(['--skill=test-skill'])

        assert_equal 1, exit_code
      end

      def test_call_without_skill_returns_error
        exit_code = RunCommand.call(['test-eval'])

        assert_equal 1, exit_code
      end
    end
  end
end
