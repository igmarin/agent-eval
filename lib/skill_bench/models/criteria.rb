# frozen_string_literal: true

require 'json'

module SkillBench
  module Models
    # Validates and processes evaluation criteria
    class Criteria
      # Validates criteria from a JSON file
      #
      # @param path [String] Path to criteria JSON file
      # @return [Hash] Validation result with success status and criteria data
      def self.call(path:)
        new(path).call
      end

      # @param path [String] Path to criteria JSON file
      def initialize(path)
        @path = path
      end

      # Validates the criteria file.
      #
      # @return [Hash] Validation result.
      def call
        return file_not_found_result unless File.exist?(path)

        data = parse_json(path)
        return data unless data[:success]

        parsed = data[:response][:data]
        validation = validate(parsed)
        return validation unless validation[:success]

        { success: true, response: { criteria: parsed } }
      end

      private

      attr_reader :path

      def file_not_found_result
        { success: false, response: { error: { message: "File not found: #{path}" } } }
      end

      def parse_json(file_path)
        parsed = JSON.parse(File.read(file_path), symbolize_names: true)
        { success: true, response: { data: parsed } }
      rescue JSON::ParserError => e
        { success: false, response: { error: { message: "Invalid JSON: #{e.message}" } } }
      end

      def validate(data)
        dim_result = validate_dimensions(data.fetch(:dimensions, []))
        return dim_result unless dim_result[:success]

        field_result = validate_required_fields(data)
        return field_result unless field_result[:success]

        threshold_result = validate_pass_threshold(data[:pass_threshold])
        return threshold_result unless threshold_result[:success]

        validate_minimum_delta(data[:minimum_delta])
      end

      def validate_dimensions(dimensions)
        return invalid_dimensions_result unless dimensions.is_a?(Array)
        return invalid_dimensions_result unless dimensions.all? { |dim| dim.is_a?(Hash) && dim[:name] && dim[:max_score] }

        total = dimensions.sum { |dim| dim[:max_score] || 0 }
        return score_sum_result(total) unless total == 100

        { success: true, response: {} }
      end

      def invalid_dimensions_result
        { success: false, response: { error: { message: 'Invalid dimensions format' } } }
      end

      def score_sum_result(total)
        { success: false, response: { error: { message: "Dimension scores must sum to 100, got #{total}" } } }
      end

      def validate_required_fields(data)
        missing = %i[pass_threshold minimum_delta].select { |field| data[field].nil? }
        return { success: true, response: {} } if missing.empty?

        { success: false, response: { error: { message: "Missing required fields: #{missing.join(', ')}" } } }
      end

      def validate_pass_threshold(value)
        return { success: true, response: {} } if value.is_a?(Integer) && value.between?(0, 100)

        { success: false, response: { error: { message: 'Pass threshold must be between 0 and 100' } } }
      end

      def validate_minimum_delta(value)
        return { success: true, response: {} } if value.is_a?(Integer) && value >= 0

        { success: false, response: { error: { message: 'Minimum delta must be non-negative integer' } } }
      end
    end
  end
end
