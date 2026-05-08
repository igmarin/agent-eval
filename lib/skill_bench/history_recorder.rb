# frozen_string_literal: true

require_relative 'history_recorder/persistence_service'
require_relative 'history_recorder/summary_service'
require_relative 'history_recorder/history_path_resolver'
require_relative 'history_recorder/history_file'

# Top-level namespace for the Rails Agent Evaluator.
module SkillBench
  # Records evaluation results into a historical benchmarks file.
  # Delegates to specialized services following Single Responsibility Principle.
  class HistoryRecorder
    # The default file where historical benchmarks are stored.
    HISTORY_FILE = File.join(__dir__, '..', 'benchmarks.json')

    # Records evaluation results into a historical benchmarks file.
    # Delegates to PersistenceService.
    def self.record(results, source_path:, model:)
      PersistenceService.record(results, source_path: source_path, model: model)
    end

    # Loads existing history from the benchmarks file.
    # Delegates to HistoryFile.
    def self.load_history(path = HISTORY_FILE)
      HistoryFile.load(path)
    end

    # Summarizes the results of multiple tasks.
    # Delegates to SummaryService.
    def self.summarize(tasks)
      SummaryService.summarize(tasks)
    end

    # Logs errors with backtrace.
    # Delegates to ErrorLogger.
    def self.log_error(exception)
      SkillBench::ErrorLogger.log_error(exception, 'HistoryRecorder')
    end
  end
end
