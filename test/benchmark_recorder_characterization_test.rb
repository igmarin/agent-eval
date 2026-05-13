# frozen_string_literal: true

require 'test_helper'
require 'json'

module SkillBench
  class BenchmarkRecorderCharacterizationTest < Minitest::Test
    def setup
      @tmp_dir = Dir.mktmpdir('benchmark_char_test')
      @history_file = File.join(@tmp_dir, 'history.json')
      @recorder = BenchmarkRecorder.new(history_file: @history_file)
    end

    def teardown
      FileUtils.rm_rf(@tmp_dir)
    end

    # Characterization test: Records evaluation result to history file
    def test_record_creates_history_file_with_correct_structure
      result = build_complete_result

      response = @recorder.record(result)

      assert response[:success]
      assert response[:response][:recorded]
      assert_path_exists @history_file

      history = JSON.parse(File.read(@history_file))

      assert_equal 1, history.size

      entry = history.first

      assert entry['timestamp']
      assert_equal 'test-eval', entry['eval_name']
      assert_equal ['test-skill'], entry['skill_names']
      assert entry['verdict']
      assert_equal 30, entry['baseline_total']
      assert_equal 80, entry['context_total']
    end

    # Characterization test: Handles file corruption with backup recovery
    def test_load_history_handles_corruption_with_backup
      # Create initial history
      @recorder.record(build_complete_result)

      # Corrupt main file
      File.write(@history_file, 'invalid json{')

      history = @recorder.history

      assert_equal 1, history.size
      assert_equal 'test-eval', history.first[:eval_name]
    end

    # Characterization test: Computes trend direction correctly
    def test_trend_for_computes_direction_and_deltas
      @recorder.record(build_complete_result(baseline_total: 30, context_total: 80))

      trend = @recorder.trend_for(build_complete_result(baseline_total: 35, context_total: 90))

      assert_equal :improved, trend[:baseline_trend]
      assert_equal :improved, trend[:context_trend]
      assert_equal 5, trend[:baseline_delta]
      assert_equal 10, trend[:context_delta]
      assert trend[:previous_run]
    end

    # Characterization test: Returns nil when no matching history exists
    def test_trend_for_returns_nil_without_matching_history
      @recorder.record(build_complete_result(eval_name: 'different-eval'))

      trend = @recorder.trend_for(build_complete_result(eval_name: 'test-eval'))

      assert_nil trend
    end

    # Characterization test: Only compares entries with same eval_name and skill_names
    def test_trend_for_filters_by_eval_and_skills
      @recorder.record(build_complete_result(eval_name: 'test-eval', skill_names: ['skill-a']))
      @recorder.record(build_complete_result(eval_name: 'test-eval', skill_names: ['skill-b']))

      trend = @recorder.trend_for(build_complete_result(eval_name: 'test-eval', skill_names: ['skill-a']))

      assert_equal :unchanged, trend[:context_trend] # Matches first entry
    end

    # Characterization test: Error handling during recording
    def test_record_handles_errors_gracefully
      # Make file unwritable
      FileUtils.chmod(0o444, @tmp_dir)

      response = @recorder.record(build_complete_result)

      refute response[:success]
      assert response[:response][:error][:message]
    ensure
      FileUtils.chmod(0o755, @tmp_dir)
    end

    private

    def build_complete_result(baseline_total: 30, context_total: 80, eval_name: 'test-eval', skill_names: ['test-skill'])
      {
        success: true,
        eval_name: eval_name,
        skill_names: skill_names,
        response: {
          report: Struct.new(:verdict, :baseline_total, :context_total, :deltas, keyword_init: true).new(
            verdict: true,
            baseline_total: baseline_total,
            context_total: context_total,
            deltas: { 'correctness' => 16 }
          )
        }
      }
    end
  end
end
