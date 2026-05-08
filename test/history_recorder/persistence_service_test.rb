# frozen_string_literal: true

require 'test_helper'
require 'stringio'

module SkillBench
  class HistoryRecorder
    class PersistenceServiceTest < Minitest::Test
      # ============================================================
      # Characterization tests for PersistenceService orchestration
      # ============================================================

      # record: returns false when results[:success] is false
      def test_record_returns_false_when_results_not_successful
        results = { success: false }

        refute PersistenceService.record(results, source_path: 'test', model: 'gpt-4')
      end

      # record: returns false when no history file can be resolved
      def test_record_returns_false_when_no_history_file_found
        results = { success: true, tasks: [] }
        HistoryPathResolver.stubs(:resolve).returns(nil)

        refute PersistenceService.record(results, source_path: 'test', model: 'gpt-4')
      end

      # record: builds entry, appends to history, writes, returns true
      def test_record_appends_entry_and_writes
        results = {
          success: true,
          tasks: [{ judge_score: '{"baseline_score": 80}' }]
        }
        fixed_path = '/tmp/benchmarks.json'
        existing_history = [{ timestamp: '2024-01-01T00:00:00Z' }]

        HistoryPathResolver.stubs(:resolve).returns(fixed_path)
        HistoryFile.stubs(:load).with(fixed_path).returns(existing_history)

        captured_data = nil
        HistoryFile.stubs(:write).with(fixed_path, anything) do |_path, data|
          captured_data = data
        end

        assert PersistenceService.record(results, source_path: 'skills/test', model: 'gpt-4')

        assert_equal 2, captured_data.length
        assert_equal 'skills/test', captured_data.last[:source_path]
        assert_equal 'gpt-4', captured_data.last[:model]
        assert captured_data.last[:timestamp]
        assert captured_data.last[:summary]
      end

      # record: rescues StandardError, logs, returns false
      def test_record_rescues_errors_and_returns_false
        results = { success: true, tasks: [] }
        HistoryPathResolver.stubs(:resolve).raises(StandardError, 'boom')

        stderr_output = StringIO.new
        original_stderr = $stderr
        $stderr = stderr_output

        refute PersistenceService.record(results, source_path: 'test', model: 'gpt-4')
        assert_match(/HistoryRecorder: boom/, stderr_output.string)
      ensure
        $stderr = original_stderr
      end
    end
  end
end
