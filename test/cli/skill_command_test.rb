# frozen_string_literal: true

require 'test_helper'

module SkillBench
  module Cli
    class SkillCommandTest < Minitest::Test
      def setup
        @tmp_dir = Dir.mktmpdir('cli_skill_test')
        @original_dir = Dir.pwd
        Dir.chdir(@tmp_dir)
        FileUtils.mkdir('skills')
      end

      def teardown
        Dir.chdir(@original_dir)
        FileUtils.rm_rf(@tmp_dir)
      end

      def test_call_new_creates_skill
        exit_code = SkillCommand.call(['new', 'my-skill'])

        assert_equal 0, exit_code
        assert_path_exists 'skills/my-skill/SKILL.md'
      end

      def test_call_new_with_mode
        exit_code = SkillCommand.call(['new', 'my-skill', '--mode=advanced'])

        assert_equal 0, exit_code
        assert_path_exists 'skills/my-skill/skill.rb'
      end

      def test_call_new_without_name_returns_error
        exit_code = SkillCommand.call(['new'])

        assert_equal 1, exit_code
      end

      def test_call_with_help
        exit_code = SkillCommand.call(['--help'])

        assert_equal 0, exit_code
      end

      def test_call_with_nil_action_shows_help
        exit_code = SkillCommand.call([])

        assert_equal 0, exit_code
      end

      def test_call_with_unknown_action_returns_error
        exit_code = SkillCommand.call(['unknown'])

        assert_equal 1, exit_code
      end
    end
  end
end
