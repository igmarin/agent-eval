# frozen_string_literal: true

require 'test_helper'
require 'stringio'

module SkillBench
  class HistoryRecorderTest < Minitest::Test
    def test_record_persists_entry_on_success
      results = {
        success: true,
        tasks: [{ judge_score: '{"baseline_score": 80, "context_score": 90}' }]
      }
      fixed_path = '/tmp/benchmarks.json'

      SkillBench::HistoryRecorder::HistoryPathResolver.stubs(:resolve).returns(fixed_path)
      SkillBench::HistoryRecorder::HistoryFile.stubs(:load).with(fixed_path).returns([])

      captured_data = nil
      SkillBench::HistoryRecorder::HistoryFile.stubs(:write).with(fixed_path, anything) do |_path, data|
        captured_data = data
      end

      SkillBench::HistoryRecorder.record(results, source_path: 'skills/test', model: 'gpt-4')

      assert_equal 1, captured_data.length
      assert_equal 'skills/test', captured_data.first[:source_path]
      assert_equal 'gpt-4', captured_data.first[:model]
      assert captured_data.first[:timestamp]
      assert captured_data.first[:summary]
    end

    def test_record_does_nothing_on_failure
      results = { success: false }
      File.expects(:open).never
      SkillBench::HistoryRecorder.record(results, source_path: 'test', model: 'gpt-4')
    end
  end
end
