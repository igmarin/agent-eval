# frozen_string_literal: true

require 'json'
require 'pathname'

module SkillBench
  # Handles history file persistence operations including backup management
  class HistoryPersistence
    # @param history_file [String] Path to the history JSON file
    def initialize(history_file)
      @history_file = File.expand_path(history_file)
    end

    # Loads history from file with corruption recovery
    #
    # @return [Array<Hash>] List of historical entries
    def load
      return [] unless File.exist?(history_file)

      JSON.parse(File.read(history_file), symbolize_names: true)
    rescue JSON::ParserError => e
      backup = read_backup
      return backup if backup

      SkillBench::ErrorLogger.log_error(e, "History file #{history_file} corrupted")
      []
    end

    # Writes history to file with atomic operation and backup
    #
    # @param history [Array<Hash>] History entries to write
    # @raise [SystemCallError] If file operations fail due to permissions or I/O errors
    def write(history)
      json = JSON.pretty_generate(history)
      temp_file = "#{history_file}.tmp"
      File.write(temp_file, json)
      File.rename(temp_file, history_file)
      File.write("#{history_file}.bak", json) if File.exist?(history_file)
    end

    private

    attr_reader :history_file

    # Reads backup file if it exists
    #
    # @return [Array<Hash>, nil] Backup data or nil if unavailable
    def read_backup
      backup_path = "#{history_file}.bak"
      return nil unless File.exist?(backup_path)

      JSON.parse(File.read(backup_path), symbolize_names: true)
    rescue JSON::ParserError
      nil
    end
  end
end
