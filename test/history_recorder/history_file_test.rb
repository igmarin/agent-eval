# frozen_string_literal: true

require 'test_helper'
require 'stringio'
require 'tmpdir'

module SkillBench
  class HistoryRecorder
    class HistoryFileTest < Minitest::Test
      # load: returns empty array when file missing
      def test_load_returns_empty_array_when_file_missing
        assert_empty HistoryFile.load('/nonexistent.json')
      end

      # load: parses existing JSON file with symbolized keys
      def test_load_parses_existing_json
        Dir.mktmpdir do |dir|
          path = File.join(dir, 'history.json')
          data = [{ 'timestamp' => '2024-01-01T00:00:00Z', 'model' => 'gpt-4' }]
          File.write(path, JSON.generate(data))

          history = HistoryFile.load(path)

          assert_equal 1, history.length
          assert_equal 'gpt-4', history.first[:model]
          assert_equal '2024-01-01T00:00:00Z', history.first[:timestamp]
        end
      end

      # load: returns empty array on JSON parse error, logs warning
      def test_load_returns_empty_array_on_parse_error
        Dir.mktmpdir do |dir|
          path = File.join(dir, 'corrupt.json')
          File.write(path, 'not json')

          stderr_output = StringIO.new
          original_stderr = $stderr
          $stderr = stderr_output

          assert_empty HistoryFile.load(path)
          assert_match(/corrupted benchmarks\.json/, stderr_output.string)
        ensure
          $stderr = original_stderr
        end
      end

      # load: returns empty array on read error, logs error
      def test_load_returns_empty_array_on_read_error
        stderr_output = StringIO.new
        original_stderr = $stderr
        $stderr = stderr_output

        File.stubs(:exist?).with('/unreadable.json').returns(true)
        File.stubs(:read).with('/unreadable.json').raises(Errno::EACCES, 'Permission denied')

        assert_empty HistoryFile.load('/unreadable.json')
        assert_match(/Permission denied/, stderr_output.string)
      ensure
        $stderr = original_stderr
      end

      # write: creates temp file, locks, writes JSON, renames atomically
      def test_write_creates_temp_file_with_lock_and_renames
        Dir.mktmpdir do |dir|
          path = File.join(dir, 'history.json')
          data = [{ model: 'gpt-4', timestamp: '2024-01-01T00:00:00Z' }]

          HistoryFile.write(path, data)

          assert_path_exists path
          content = JSON.parse(File.read(path), symbolize_names: true)

          assert_equal 1, content.length
          assert_equal 'gpt-4', content.first[:model]
        end
      end

      # write: creates parent directories if needed
      def test_write_creates_parent_directories
        Dir.mktmpdir do |dir|
          path = File.join(dir, 'nested', 'deep', 'history.json')
          data = [{ model: 'gpt-4' }]

          HistoryFile.write(path, data)

          assert_path_exists path
        end
      end

      # write: logs info to Rails.logger when available
      def test_write_logs_info_to_rails_logger
        Dir.mktmpdir do |dir|
          path = File.join(dir, 'history.json')
          data = [{ model: 'gpt-4' }]

          spy = SpyLogger.new
          fake_rails = Object.new
          fake_rails.define_singleton_method(:respond_to?) { |m| m == :logger }
          fake_rails.define_singleton_method(:logger) { spy }
          Object.const_set(:Rails, fake_rails)

          HistoryFile.write(path, data)

          assert spy.messages.any? { |m| m.include?('History recorded to') },
                 "Expected log message about history recording, got: #{spy.messages.inspect}"
        ensure
          Object.send(:remove_const, :Rails) if defined?(Rails)
        end
      end
    end
  end
end

# Simple spy for capturing logger calls
class SpyLogger
  attr_reader :messages

  def initialize
    @messages = []
  end

  def info(msg)
    @messages << msg
  end
end
