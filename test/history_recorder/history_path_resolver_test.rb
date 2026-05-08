# frozen_string_literal: true

require 'test_helper'
require 'stringio'

module SkillBench
  class HistoryRecorder
    class HistoryPathResolverTest < Minitest::Test
      FIXTURE_PWD = '/tmp/skill_bench_test'

      def with_env(vars)
        old = {}
        vars.each do |k, v|
          old[k] = ENV.fetch(k, nil)
          if v.nil?
            ENV.delete(k)
          else
            ENV[k] = v
          end
        end
        yield
      ensure
        old.each do |k, v|
          if v.nil?
            ENV.delete(k)
          else
            ENV[k] = v
          end
        end
      end

      def setup
        Dir.stubs(:pwd).returns(FIXTURE_PWD)
      end

      # resolve: returns env path when valid and writable
      def test_resolve_returns_env_path_when_valid
        env_path = File.join(FIXTURE_PWD, 'custom_benchmarks.json')

        with_env('SKILL_BENCH_HISTORY_FILE' => env_path) do
          File.stubs(:writable?).returns(true)
          FileUtils.stubs(:mkpath)

          assert_equal env_path, HistoryPathResolver.resolve
        end
      end

      # resolve: rejects env path outside allowed prefixes, warns, falls back
      def test_resolve_warns_and_returns_nil_when_env_path_outside_allowed_prefixes
        with_env('SKILL_BENCH_HISTORY_FILE' => '/etc/passwd') do
          stderr_output = StringIO.new
          original_stderr = $stderr
          $stderr = stderr_output

          File.stubs(:writable?).returns(false)
          FileUtils.stubs(:mkpath)

          assert_nil HistoryPathResolver.resolve
          assert_match(/SKILL_BENCH_HISTORY_FILE.*rejected/, stderr_output.string)
        ensure
          $stderr = original_stderr
        end
      end

      # resolve: falls back to cwd benchmarks.json
      def test_resolve_falls_back_to_cwd
        with_env('SKILL_BENCH_HISTORY_FILE' => nil) do
          cwd_path = File.join(FIXTURE_PWD, 'benchmarks.json')

          File.stubs(:writable?).with(FIXTURE_PWD).returns(true)

          assert_equal cwd_path, HistoryPathResolver.resolve
        end
      end

      # resolve: falls back to local share path
      def test_resolve_falls_back_to_local_share
        with_env('SKILL_BENCH_HISTORY_FILE' => nil) do
          local_path = File.join(Dir.home, '.local', 'share', 'skill_bench', 'benchmarks.json')

          File.stubs(:writable?).with(FIXTURE_PWD).returns(false)
          File.stubs(:writable?).with(File.dirname(local_path)).returns(true)
          FileUtils.stubs(:mkpath)

          assert_equal local_path, HistoryPathResolver.resolve
        end
      end

      # resolve: returns nil and warns when nothing is writable
      def test_resolve_returns_nil_when_nothing_writable
        with_env('SKILL_BENCH_HISTORY_FILE' => nil) do
          File.stubs(:writable?).returns(false)
          FileUtils.stubs(:mkpath)

          stderr_output = StringIO.new
          original_stderr = $stderr
          $stderr = stderr_output

          assert_nil HistoryPathResolver.resolve
          assert_match(/Could not find writable location/, stderr_output.string)
        ensure
          $stderr = original_stderr
        end
      end
    end
  end
end
