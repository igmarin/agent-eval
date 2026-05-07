# frozen_string_literal: true

require_relative '../test_helper'
require 'skill_bench/history_recorder'

class HistoryRecorderTest < Minitest::Test
  def setup
    @history_file = SkillBench::HistoryRecorder::HISTORY_FILE
  end

  def test_load_history_returns_empty_array_when_file_missing
    File.expects(:exist?).with(@history_file).returns(false)

    assert_equal [], SkillBench::HistoryRecorder.load_history
  end

  def test_load_history_returns_empty_array_on_json_parse_error
    File.expects(:exist?).with(@history_file).returns(true)
    File.expects(:read).with(@history_file).returns('invalid json')

    assert_equal [], SkillBench::HistoryRecorder.load_history
  end

  def test_load_history_returns_parsed_json_when_valid
    data = [{ timestamp: '2023-01-01', source_path: 'test', summary: {} }]
    File.expects(:exist?).with(@history_file).returns(true)
    File.expects(:read).with(@history_file).returns(JSON.generate(data))

    result = SkillBench::HistoryRecorder.load_history

    assert_equal 1, result.size
    assert_equal 'test', result.first[:source_path]
  end

  def test_summarize_handles_empty_tasks
    assert_equal ({}), SkillBench::HistoryRecorder.summarize([])
    assert_equal ({}), SkillBench::HistoryRecorder.summarize(nil)
  end

  def test_summarize_processes_mixed_input_types
    tasks = [
      { judge_score: '{"baseline_score": 50, "context_score": 70}' }, # JSON string
      { judge_score: { baseline_score: 60, context_score: 80 } }, # Hash
      { judge_score: 'invalid' },                                     # Bad JSON
      { judge_score: nil }                                            # Nil
    ]

    summary = SkillBench::HistoryRecorder.summarize(tasks)

    # 4 tasks.
    # Baseline scores: 50, 60, 0, 0 => sum 110. Avg 110/4 = 27.5
    # Context scores: 70, 80, 0, 0 => sum 150. Avg 150/4 = 37.5
    # Improvement: (37.5 - 27.5) = 10.0

    assert_equal 4, summary[:task_count]
    assert_in_delta(27.5, summary[:average_baseline])
    assert_in_delta(37.5, summary[:average_context])
    assert_in_delta(10.0, summary[:improvement])
  end

  def test_record_persists_entry_on_success
    results = {
      success: true,
      tasks: [{ judge_score: '{"baseline_score": 80, "context_score": 90}' }]
    }
    fixed_path = '/tmp/benchmarks.json'

    # Stub PersistenceService methods
    SkillBench::HistoryRecorder::PersistenceService.stubs(:determine_history_file).returns(fixed_path)
    SkillBench::HistoryRecorder::PersistenceService.stubs(:load_history).with(fixed_path).returns([])

    # Expect File.write with the new entry to the fixed path
    File.expects(:write).with(fixed_path, all_of(
                                            regexp_matches(%r{"source_path": "skills/test"}),
                                            regexp_matches(/"model": "gpt-4"/),
                                            regexp_matches(/"average_baseline": 80.0/),
                                            regexp_matches(/"improvement": 10.0/)
                                          )).returns(true)

    SkillBench::HistoryRecorder.record(results, source_path: 'skills/test', model: 'gpt-4')
  end

  def test_record_does_nothing_on_failure
    results = { success: false }
    File.expects(:write).never
    SkillBench::HistoryRecorder.record(results, source_path: 'test', model: 'gpt-4')
  end
end
