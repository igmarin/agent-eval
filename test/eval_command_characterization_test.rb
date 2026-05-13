# frozen_string_literal: true

require 'test_helper'
require 'stringio'

module SkillBench
  module Cli
    class EvalCommandCharacterizationTest < Minitest::Test
      def setup
        @tmp_dir = Dir.mktmpdir('cli_eval_char_test')
        @original_dir = Dir.pwd
        Dir.chdir(@tmp_dir)
        FileUtils.mkdir('evals')
        FileUtils.mkdir_p('skills/test-skill')
        File.write('skills/test-skill/SKILL.md', <<~MARKDOWN)
          # Test Skill
          This is a test skill for characterization tests.
        MARKDOWN

        @original_stdout = $stdout
        @original_stderr = $stderr
        $stdout = StringIO.new
        $stderr = StringIO.new
      end

      def teardown
        $stdout = @original_stdout
        $stderr = @original_stderr
        Dir.chdir(@original_dir)
        FileUtils.rm_rf(@tmp_dir)
      end

      # Characterization test: Handles eval new command successfully
      def test_eval_new_creates_eval_with_default_runtime
        exit_code = EvalCommand.call(%w[new test-eval])

        assert_equal 0, exit_code
        assert_match(/Created eval: test-eval/, $stdout.string)
      end

      # Characterization test: Handles eval new with custom runtime
      def test_eval_new_with_runtime_option
        exit_code = EvalCommand.call(['new', 'test-eval', '--runtime', 'rails'])

        assert_equal 0, exit_code
        assert_match(/Created eval: test-eval/, $stdout.string)
      end

      # Characterization test: Handles eval generate command successfully
      def test_eval_generate_creates_eval_from_skill
        exit_code = EvalCommand.call(%w[generate test-skill])

        assert_equal 0, exit_code
        assert_match(/Generated eval: test-skill-eval from skill: test-skill/, $stdout.string)
      end

      # Characterization test: Handles eval generate with custom name
      def test_eval_generate_with_custom_name
        exit_code = EvalCommand.call(%w[generate test-skill --name custom-eval])

        assert_equal 0, exit_code
        assert_match(/Generated eval: custom-eval from skill: test-skill/, $stdout.string)
      end

      # Characterization test: Shows help for eval command
      def test_eval_help_shows_usage
        exit_code = EvalCommand.call(['help'])

        assert_equal 0, exit_code
        assert_match(/Usage: skill-bench eval new/, $stdout.string)
        assert_match(/Usage: skill-bench eval generate/, $stdout.string)
      end

      # Characterization test: Handles unknown action
      def test_eval_unknown_action_shows_error
        exit_code = EvalCommand.call(['unknown'])

        assert_equal 1, exit_code
        assert_match(/Unknown eval action: unknown/, $stderr.string)
      end

      # Characterization test: Handles missing eval name
      def test_eval_new_missing_name_shows_error
        exit_code = EvalCommand.call(['new'])

        assert_equal 1, exit_code
        assert_match(/Error: eval name is required/, $stderr.string)
      end

      # Characterization test: Handles missing skill name for generate
      def test_eval_generate_missing_skill_shows_error
        exit_code = EvalCommand.call(%w[generate])

        assert_equal 1, exit_code
        assert_match(/Error: skill name is required/, $stderr.string)
      end

      # Characterization test: Handles non-existent skill for generate
      def test_eval_generate_nonexistent_skill_shows_error
        exit_code = EvalCommand.call(%w[generate nonexistent-skill])

        assert_equal 1, exit_code
        assert_match(/Error: Skill not found: nonexistent-skill/, $stderr.string)
      end

      # Characterization test: Handles generate with invalid eval name
      def test_eval_generate_invalid_name_shows_error
        exit_code = EvalCommand.call(%w[generate test-skill --name ..])

        assert_equal 1, exit_code
        assert_match(/Error: Invalid eval name/, $stderr.string)
      end

      # Characterization test: Handles help flag for new command
      def test_eval_new_help_shows_usage
        exit_code = EvalCommand.call(['new', '--help'])

        assert_equal 0, exit_code
        assert_match(/Usage: skill-bench eval new/, $stdout.string)
      end

      # Characterization test: Handles help flag for generate command
      def test_eval_generate_help_shows_usage
        exit_code = EvalCommand.call(%w[generate --help])

        assert_equal 0, exit_code
        assert_match(/Usage: skill-bench eval generate/, $stdout.string)
      end
    end
  end
end
