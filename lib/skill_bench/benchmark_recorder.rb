# frozen_string_literal: true

require 'json'
require 'pathname'
require 'time'

module SkillBench
  # Records evaluation results to a local history file and computes trends.
  class BenchmarkRecorder
    DEFAULT_HISTORY_FILE = '.skill-bench-history.json'

    # @param history_file [String] Path to the history JSON file.
    def initialize(history_file: DEFAULT_HISTORY_FILE)
      @history_file = File.expand_path(history_file)
    end

    # Records an evaluation result.
    #
    # @param result [Hash] The evaluation result from EvaluationRunner.
    # @return [Hash] Service response.
    def record(result)
      history = load_history
      history << extract_entry(result)
      write_history(history)

      { success: true, response: { recorded: true } }
    rescue StandardError => e
      SkillBench::ErrorLogger.log_error(e, 'BenchmarkRecorder Error')
      { success: false, response: { error: { message: e.message } } }
    end

    # Loads the full history.
    #
    # @return [Array<Hash>] List of historical entries.
    def history
      load_history
    end

    # Computes the trend of the given result against the most recent matching history entry.
    #
    # @param result [Hash] The current evaluation result.
    # @return [Hash, nil] Trend data or nil if no matching history exists.
    def trend_for(result)
      entries = load_history
      current = extract_entry(result)
      matching = filter_matching_entries(entries, current)
      return nil if matching.empty?

      previous = matching.last
      current_baseline = current[:baseline_total]
      current_context = current[:context_total]
      previous_baseline = previous[:baseline_total]
      previous_context = previous[:context_total]
      return nil unless current_baseline && current_context && previous_baseline && previous_context

      {
        baseline_trend: trend_direction(current_baseline, previous_baseline),
        context_trend: trend_direction(current_context, previous_context),
        baseline_delta: current_baseline - previous_baseline,
        context_delta: current_context - previous_context,
        previous_run: previous[:timestamp]
      }
    end

    private

    attr_reader :history_file

    def load_history
      return [] unless File.exist?(history_file)

      JSON.parse(File.read(history_file), symbolize_names: true)
    rescue JSON::ParserError => e
      backup = read_backup
      return backup if backup

      SkillBench::ErrorLogger.log_error(e, "History file #{history_file} corrupted")
      []
    end

    def read_backup
      backup_path = "#{history_file}.bak"
      return nil unless File.exist?(backup_path)

      JSON.parse(File.read(backup_path), symbolize_names: true)
    rescue JSON::ParserError
      nil
    end

    def write_history(history)
      json = JSON.pretty_generate(history)
      temp_file = "#{history_file}.tmp"
      File.write(temp_file, json)
      File.rename(temp_file, history_file)
      File.write("#{history_file}.bak", json) if File.exist?(history_file)
    end

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

    def filter_matching_entries(entries, current)
      entries.select do |entry|
        entry[:eval_name] == current[:eval_name] &&
          entry[:skill_names] == current[:skill_names]
      end
    end

    def trend_direction(current, previous)
      return :unchanged if current == previous

      current > previous ? :improved : :regressed
    end
  end
end
