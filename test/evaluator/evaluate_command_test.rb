# frozen_string_literal: true

require 'stringio'
require 'test_helper'
require_relative '../../lib/skill_bench/evaluate_command'

module SkillBench
  class EvaluateCommandTest < Minitest::Test
    def setup
      @original_dir = Dir.pwd
      @stdout = StringIO.new
    end

    def teardown
      Dir.chdir(@original_dir)
    end

    def test_call_accepts_eval_without_explicit_skill_override
      Runner.expects(:call).with(has_entries(
                                   eval_folder_path: File.expand_path('evals/skills/patterns/ruby-service-objects/basic-service-object'),
                                   skill_path: nil
                                 )).returns(success_result('skills/patterns/ruby-service-objects'))
      HistoryRecorder.expects(:record).with(
        has_entries(success: true),
        source_path: 'skills/patterns/ruby-service-objects',
        model: SkillBench::Config.model
      )

      exit_code = EvaluateCommand.call(
        %w[--eval evals/skills/patterns/ruby-service-objects/basic-service-object],
        stdout: @stdout
      )

      assert_equal 0, exit_code
    end

    def test_call_passes_explicit_skill_override_through_to_runner
      Runner.expects(:call).with(has_entries(
                                   eval_folder_path: File.expand_path('evals/workflows/rails-tdd-loop/full-feature'),
                                   skill_path: File.expand_path('skills/patterns/ruby-service-objects')
                                 )).returns(success_result('skills/patterns/ruby-service-objects'))
      HistoryRecorder.expects(:record).with(
        has_entries(success: true),
        source_path: 'skills/patterns/ruby-service-objects',
        model: SkillBench::Config.model
      )

      exit_code = EvaluateCommand.call(
        [
          '--eval', 'evals/workflows/rails-tdd-loop/full-feature',
          '--skill', 'skills/patterns/ruby-service-objects'
        ],
        stdout: @stdout
      )

      assert_equal 0, exit_code
    end

    def test_call_returns_error_when_eval_is_missing
      Runner.expects(:call).never
      HistoryRecorder.expects(:record).never

      exit_code = EvaluateCommand.call([], stdout: @stdout)

      assert_equal 1, exit_code
      assert_match(/--eval option is required/, @stdout.string)
    end

    def test_call_handles_hash_judge_scores_without_json_parse
      Runner.expects(:call).with(has_entry(eval_folder_path: File.expand_path('evals/skills/example'))).returns(
        success_result('skills/patterns/ruby-service-objects').merge(
          tasks: [task_result(judge_score: { 'baseline_score' => 70, 'context_score' => 90, 'reasoning' => 'hash result' })]
        )
      )
      HistoryRecorder.expects(:record)

      exit_code = EvaluateCommand.call(%w[--eval evals/skills/example], stdout: @stdout)

      assert_equal 0, exit_code
      assert_match(%r{Baseline Score: 70/100}, @stdout.string)
      assert_match(/hash result/, @stdout.string)
    end

    def test_call_parses_json_string_with_markdown_backticks
      raw_score = "```json\n{\"baseline_score\": 75, \"context_score\": 95, \"reasoning\": \"parsed markdown\"}\n```"
      Runner.expects(:call).with(has_entry(eval_folder_path: File.expand_path('evals/skills/example'))).returns(
        success_result('skills/patterns/ruby-service-objects').merge(
          tasks: [task_result(judge_score: raw_score)]
        )
      )
      HistoryRecorder.expects(:record)

      exit_code = EvaluateCommand.call(%w[--eval evals/skills/example], stdout: @stdout)

      assert_equal 0, exit_code
      assert_match(%r{Baseline Score: 75/100}, @stdout.string)
      assert_match(/parsed markdown/, @stdout.string)
    end

    def test_call_handles_nil_judge_scores_without_type_error
      Runner.expects(:call).with(has_entry(eval_folder_path: File.expand_path('evals/skills/example'))).returns(
        success_result('skills/patterns/ruby-service-objects').merge(
          tasks: [task_result(judge_score: nil)]
        )
      )
      HistoryRecorder.expects(:record)

      exit_code = EvaluateCommand.call(%w[--eval evals/skills/example], stdout: @stdout)

      assert_equal 0, exit_code
      assert_match(/Could not parse judge JSON response/, @stdout.string)
    end

    def test_parse_options_returns_false_for_empty_args
      SkillBench::Services::OptionParserService.stubs(:call).returns(
        { success: false, response: { error: { message: 'Missing required option' } } }
      )
      command = EvaluateCommand.new([], stdout: @stdout)
      result = command.send(:parse_options?)

      refute result
    end

    def test_parse_options_returns_true_for_valid_args
      Runner.stubs(:call).returns(success_result('test'))
      HistoryRecorder.stubs(:record)
      command = EvaluateCommand.new(
        ['--eval', 'evals/skills/example'],
        stdout: @stdout
      )
      result = command.send(:parse_options?)

      assert result
    end

    def test_parse_options_returns_false_when_option_parser_fails
      SkillBench::Services::OptionParserService.stubs(:call).returns(
        { success: false, response: { error: { message: 'Invalid option' } } }
      )
      command = EvaluateCommand.new(['--invalid'], stdout: @stdout)
      result = command.send(:parse_options?)

      refute result
    end

    def test_safe_expand_path_rejects_absolute_paths_outside_cwd
      Dir.mktmpdir do |dir|
        Dir.chdir(dir) do
          command = EvaluateCommand.new([], stdout: @stdout)

          error = assert_raises(ArgumentError) do
            command.send(:safe_expand_path, '/etc/passwd')
          end

          assert_match(/outside the current working directory/, error.message)
        end
      end
    end

    def test_safe_expand_path_allows_paths_within_cwd
      Dir.mktmpdir do |dir|
        Dir.chdir(dir) do
          command = EvaluateCommand.new([], stdout: @stdout)
          path = command.send(:safe_expand_path, 'evals/my-eval')

          assert_equal File.expand_path('evals/my-eval'), path
        end
      end
    end

    private

    def success_result(source_path)
      {
        success: true,
        source_path: source_path,
        tasks: []
      }
    end

    def task_result(judge_score:)
      {
        path: 'evals/skills/example',
        judge_score: judge_score,
        baseline_diff: 'baseline diff',
        context_diff: 'context diff'
      }
    end
  end
end
