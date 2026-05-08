# frozen_string_literal: true

require 'json'
require 'fileutils'

module SkillBench
  class HistoryRecorder
    # Handles atomic read/write of benchmark history JSON files.
    class HistoryFile
      # Loads history from the given path.
      #
      # @param path [String] path to the JSON history file
      # @return [Array<Hash>] parsed history entries
      def self.load(path)
        new.load(path)
      end

      # Writes history data atomically to the given path.
      #
      # @param path [String] target file path
      # @param data [Array<Hash>] history entries to serialize
      # @return [void]
      def self.write(path, data)
        new.write(path, data)
      end

      # Loads history from the given path.
      #
      # @param path [String] path to the JSON history file
      # @return [Array<Hash>] parsed history entries
      def load(path)
        return [] unless File.exist?(path)

        JSON.parse(File.read(path), symbolize_names: true)
      rescue JSON::ParserError => e
        SkillBench::ErrorLogger.log_error(e, 'corrupted benchmarks.json')
        []
      rescue StandardError => e
        SkillBench::ErrorLogger.log_error(e, 'HistoryRecorder')
        []
      end

      # Writes history data atomically using a temp file and rename.
      #
      # @param path [String] target file path
      # @param data [Array<Hash>] history entries to serialize
      # @return [void]
      def write(path, data)
        dir = File.dirname(path)
        FileUtils.mkpath(dir)

        temp_path = "#{path}.tmp.#{Process.pid}"
        File.open(temp_path, File::WRONLY | File::CREAT | File::TRUNC, 0o644) do |file|
          file.flock(File::LOCK_EX)
          file.write(JSON.pretty_generate(data))
          file.fsync
        end
        File.rename(temp_path, path)
        logger&.info("History recorded to #{path}")
      end

      private

      def logger
        ::Rails.logger
      rescue NameError
        nil
      end
    end
  end
end
