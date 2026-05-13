# frozen_string_literal: true

require 'time'
require_relative 'history_persistence'
require_relative 'trend_calculator'

module SkillBench
  # Records evaluation results to a local history file and computes trends.
  class BenchmarkRecorder
    DEFAULT_HISTORY_FILE = '.skill-bench-history.json'

    # @param history_file [String] Path to the history JSON file.
    def initialize(history_file: DEFAULT_HISTORY_FILE)
      @persistence = HistoryPersistence.new(history_file)
    end

    # Records an evaluation result.
    #
    # @param result [Hash] The evaluation result from EvaluationRunner.
    # @return [Hash] Service response.
    def record(result)
      history = @persistence.load
      history << extract_entry(result)
      @persistence.write(history)

      { success: true, response: { recorded: true } }
    rescue SystemCallError => e
      # Handle file system errors (permissions, disk space, etc.) without logging
      { success: false, response: { error: { message: e.message } } }
    rescue StandardError => e
      # Handle other unexpected errors with logging
      SkillBench::ErrorLogger.log_error(e, 'BenchmarkRecorder Error')
      { success: false, response: { error: { message: e.message } } }
    end

    # Loads the full history.
    #
    # @return [Array<Hash>] List of historical entries.
    def history
      @persistence.load
    end

    # Computes the trend of the given result against the most recent matching history entry.
    #
    # @param result [Hash] The current evaluation result.
    # @return [Hash, nil] Trend data or nil if no matching history exists.
    def trend_for(result)
      entries = @persistence.load
      current = extract_entry(result)
      TrendCalculator.compute_trend(entries, current)
    end

    private

    def extract_entry(result)
      report = result.dig(:response, :report)
      {
        timestamp: Time.now.iso8601,
        eval_name: result[:eval_name],
        skill_names: result[:skill_names],
        verdict: report&.verdict,
        baseline_total: report&.baseline_total,
        context_total: report&.context_total,
        deltas: report&.deltas
      }
    end
  end
end
