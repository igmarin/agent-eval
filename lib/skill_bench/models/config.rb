# frozen_string_literal: true

require 'yaml'
require 'json'
require_relative 'provider'

module SkillBench
  module Models
    # Represents the skill-bench configuration loaded from skill-bench.json
    class Config
      # @param data [Hash] Raw configuration data
      # @raise [ArgumentError] if data is not a Hash
      def initialize(data = {})
        raise ArgumentError, 'Config-data must be a Hash' unless data.is_a?(Hash)

        @data = self.class.send(:recursive_symbolize_keys, data)
      end

      # Recursively convert string keys to symbols in nested Hash and Array structures
      # @param obj [Object] Object to symbolize
      # @return [Object] Object with symbolized keys
      def self.recursive_symbolize_keys(obj)
        case obj
        when Hash
          obj.each_with_object({}) do |(key, value), result|
            result[key.to_sym] = recursive_symbolize_keys(value)
          end
        when Array
          obj.map { |item| recursive_symbolize_keys(item) }
        else
          obj
        end
      end

      private_class_method :recursive_symbolize_keys

      # Load configuration from a JSON file
      # @param path [String] Path to config file (default: skill-bench.json)
      # @return [SkillBench::Models::Config] Loaded config instance
      # @raise [Errno::ENOENT] if config file not found
      def self.load(path = 'skill-bench.json')
        raw_data = JSON.parse(File.read(path), symbolize_names: true)
        new(raw_data)
      end

      # Returns the configured provider name
      # @return [String, nil] Provider name
      def provider_name
        @data[:provider]
      end

      # Returns the provider configuration
      # @return [Hash] Provider configuration
      def provider_config
        @data[:config] || {}
      end

      # Returns max execution time
      # @return [Integer] Max execution time in seconds
      def max_execution_time
        @data[:max_execution_time] || 30
      end
    end
  end
end
