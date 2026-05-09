# frozen_string_literal: true

require 'test_helper'
require 'json'

module SkillBench
  class BenchmarkRecorderTest < Minitest::Test
    def setup
      @tmp_dir = Dir.mktmpdir('benchmark_test')
      @history_file = File.join(@tmp_dir, 'history.json')
    end

    def teardown
      FileUtils.rm_rf(@tmp_dir)
    end

    def test_records_eval_result
      recorder = BenchmarkRecorder.new(history_file: @history_file)
      result = build_result

      record = recorder.record(result)

      assert record[:success]
      assert_path_exists @history_file
    end

    def test_loads_previous_runs
      recorder = BenchmarkRecorder.new(history_file: @history_file)
      recorder.record(build_result(baseline_total: 30, context_total: 80))
      recorder.record(build_result(baseline_total: 35, context_total: 85))

      history = recorder.history

      assert_equal 2, history.size
    end

    def test_computes_trend_against_previous
      recorder = BenchmarkRecorder.new(history_file: @history_file)
      recorder.record(build_result(baseline_total: 30, context_total: 80))

      trend = recorder.trend_for(build_result(baseline_total: 35, context_total: 90))

      assert_equal :improved, trend[:context_trend]
      assert_equal 10, trend[:context_delta]
      assert_equal 5, trend[:baseline_delta]
    end

    def test_computes_trend_unchanged
      recorder = BenchmarkRecorder.new(history_file: @history_file)
      recorder.record(build_result(baseline_total: 30, context_total: 80))

      trend = recorder.trend_for(build_result(baseline_total: 30, context_total: 80))

      assert_equal :unchanged, trend[:context_trend]
    end

    def test_returns_no_trend_when_no_history
      recorder = BenchmarkRecorder.new(history_file: @history_file)

      trend = recorder.trend_for(build_result)

      assert_nil trend
    end

    def test_only_compares_runs_for_same_eval_and_skill
      recorder = BenchmarkRecorder.new(history_file: @history_file)
      recorder.record(build_result(eval_name: 'eval-a', skill_names: ['skill-a'], context_total: 80))
      recorder.record(build_result(eval_name: 'eval-b', skill_names: ['skill-b'], context_total: 50))

      trend = recorder.trend_for(build_result(eval_name: 'eval-a', skill_names: ['skill-a'], context_total: 90))

      assert_equal :improved, trend[:context_trend]
      assert_equal 10, trend[:context_delta]
    end

    def test_returns_no_trend_when_no_matching_eval_or_skill
      recorder = BenchmarkRecorder.new(history_file: @history_file)
      recorder.record(build_result(eval_name: 'eval-a', skill_names: ['skill-a'], context_total: 80))

      trend = recorder.trend_for(build_result(eval_name: 'eval-b', skill_names: ['skill-b'], context_total: 90))

      assert_nil trend
    end

    private

    def build_result(baseline_total: 30, context_total: 80, eval_name: 'test-eval', skill_names: ['test-skill'])
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
