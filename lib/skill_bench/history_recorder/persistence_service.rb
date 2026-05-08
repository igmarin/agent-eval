# frozen_string_literal: true

module SkillBench
  class HistoryRecorder
    # Orchestrates recording evaluation results to the history file.
    # Thin service that delegates path resolution and file I/O to
    # HistoryPathResolver and HistoryFile respectively.
    class PersistenceService
      # Records evaluation results into a historical benchmarks file.
      #
      # @param results [Hash] The results from a Runner.call.
      # @param source_path [String] The resolved source path used for the evaluation.
      # @param model [String] The model name used for the evaluation.
      # @return [Boolean] true if recorded successfully, false otherwise.
      def self.record(results, source_path:, model:)
        return false unless results[:success]

        history_file = HistoryPathResolver.resolve
        return false unless history_file

        history = HistoryFile.load(history_file)
        entry = {
          timestamp: Time.now.iso8601,
          source_path: source_path,
          model: model,
          summary: SummaryService.summarize(results[:tasks])
        }

        history << entry
        HistoryFile.write(history_file, history)
        true
      rescue StandardError => e
        SkillBench::ErrorLogger.log_error(e, 'HistoryRecorder')
        false
      end
    end
  end
end
