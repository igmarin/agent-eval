# frozen_string_literal: true

require 'fileutils'

module SkillBench
  class HistoryRecorder
    # Resolves the best writable path for storing benchmark history.
    # Checks env var, cwd, local share, and XDG data home in order.
    class HistoryPathResolver
      # Finds the best writable path for the history file.
      #
      # @return [String, nil] writable path or nil if none found
      def self.resolve
        new.resolve
      end

      # Finds the best writable path for the history file.
      #
      # @return [String, nil] writable path or nil if none found
      def resolve
        env_path || cwd_path || local_path || xdg_path || begin
          warn('Warning: Could not find writable location for benchmarks.json')
          nil
        end
      end

      private

      def env_path
        raw = ENV.fetch('SKILL_BENCH_HISTORY_FILE', '').to_s.strip
        return nil if raw.empty?

        expanded = File.expand_path(raw)
        unless contained?(expanded)
          warn "Warning: SKILL_BENCH_HISTORY_FILE '#{raw}' rejected (outside allowed directories or not writable)."
          return nil
        end
        return nil unless prepare_and_writable?(expanded)

        expanded
      end

      def cwd_path
        path = File.join(Dir.pwd, 'benchmarks.json')
        return nil unless File.writable?(File.dirname(path))

        path
      end

      def local_path
        path = File.join(Dir.home, '.local', 'share', 'skill_bench', 'benchmarks.json')
        return nil unless prepare_and_writable?(path)

        path
      end

      def xdg_path
        xdg_data_home = ENV.fetch('XDG_DATA_HOME', File.join(Dir.home, '.local', 'share'))
        path = File.join(xdg_data_home, 'skill_bench', 'benchmarks.json')
        return nil unless prepare_and_writable?(path)

        path
      end

      def contained?(path)
        path_with_sep = path + File::SEPARATOR
        allowed_prefixes.any? do |prefix|
          expanded_prefix = File.expand_path(prefix) + File::SEPARATOR
          path_with_sep.start_with?(expanded_prefix) || path == expanded_prefix.chomp(File::SEPARATOR)
        end
      end

      def allowed_prefixes
        [Dir.pwd, File.join(Dir.home, '.local', 'share', 'skill_bench')]
      end

      def prepare_and_writable?(path)
        dir_name = File.dirname(path)
        FileUtils.mkpath(dir_name)
        File.writable?(dir_name)
      rescue StandardError => e
        SkillBench::ErrorLogger.log_error(e, 'HistoryRecorder')
        false
      end
    end
  end
end
