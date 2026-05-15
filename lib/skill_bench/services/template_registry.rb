# frozen_string_literal: true

require 'json'
require_relative 'template_registry/category_data'

module SkillBench
  module Services
    # Resolves and renders evaluation templates by type and category.
    #
    # Provides a registry of template strings for generating eval scaffolding
    # (task descriptions, scoring criteria, and skill instructions) across
    # supported Rails pattern categories. Supports variable interpolation
    # using +{{variable_name}}+ syntax.
    #
    # @example Resolve a task template with variables
    #   TemplateRegistry.call(:task_md, :crud, skill_name: "UserCreator")
    #
    # @example Resolve criteria JSON
    #   TemplateRegistry.call(:criteria_json, :api)
    class TemplateRegistry
      TEMPLATE_TYPES = %i[task_md criteria_json skill_md].freeze
      CATEGORIES = REGISTRY.keys.freeze

      # @param template_type [Symbol, String] Template type (:task_md, :criteria_json, :skill_md)
      # @param category [Symbol, String] Category (:crud, :api, :background_job, etc.)
      # @param variables [Hash{Symbol, String => String}] Variables for interpolation
      # @return [String] The rendered template content
      # @raise [ArgumentError] if template_type or category is invalid
      def self.call(template_type, category, variables = {})
        new(template_type, category, variables).call
      end

      # @param template_type [Symbol, String] Template type
      # @param category [Symbol, String] Category
      # @param variables [Hash{Symbol, String => String}] Variables for interpolation
      def initialize(template_type, category, variables = {})
        @template_type = template_type.to_sym
        @category = category.to_sym
        @variables = variables
      end

      # Resolves the template and applies variable interpolation.
      #
      # @return [String] The rendered template content
      # @raise [ArgumentError] if template_type or category is invalid
      def call
        validate_template_type!
        validate_category!

        interpolate(build_template)
      end

      private

      attr_reader :template_type, :category, :variables

      def validate_template_type!
        return if TEMPLATE_TYPES.include?(template_type)

        raise ArgumentError, "Invalid template type: #{template_type}. Valid types: #{TEMPLATE_TYPES.join(', ')}"
      end

      def validate_category!
        return if CATEGORIES.include?(category)

        raise ArgumentError, "Invalid category: #{category}. Valid categories: #{CATEGORIES.join(', ')}"
      end

      def category_data
        REGISTRY.fetch(category)
      end

      def build_template
        case template_type
        when :task_md then build_task_md
        when :criteria_json then build_criteria_json
        when :skill_md then build_skill_md
        end
      end

      def interpolate(template)
        variables.reduce(template.dup) do |result, (key, value)|
          result.gsub("{{#{key}}}", value.to_s)
        end
      end

      def build_task_md
        <<~MARKDOWN
          # Task: Implement {{skill_name}} (#{category})

          ## Objective

          Implement a #{category.to_s.tr('_', ' ')} following Rails best practices and the project's established patterns.

          ## Requirements

          #{category_data.requirements}

          ## Acceptance Criteria

          - All tests pass (`bundle exec rake test`)
          - Code follows project conventions
          - YARD documentation for all public methods
          - No rubocop or reek offenses
        MARKDOWN
      end

      def build_criteria_json
        JSON.pretty_generate(
          category: category.to_s,
          dimensions: [
            { name: 'correctness', weight: 30, pass_threshold: 70 },
            { name: 'adherence',   weight: 25, pass_threshold: 60 },
            { name: 'quality',     weight: 20, pass_threshold: 60 },
            { name: 'tests',       weight: 15, pass_threshold: 80 },
            { name: 'docs',        weight: 10, pass_threshold: 50 }
          ],
          minimum_delta: 5,
          category_specific: category_data.criteria
        )
      end

      def build_skill_md
        <<~MARKDOWN
          # Skill: {{skill_name}} (#{category})

          ## Pattern

          #{category_data.pattern}

          ## Hard Rules

          1. Follow TDD — write failing test first, then implement.
          2. Use `.call` class method as entry point (Service Object pattern).
          3. Each class has one responsibility (SRP).
          4. YARD documentation on all public methods.
          5. `rubocop -A` and `reek` must pass.

          ## Template

          ```ruby
          #{category_data.code_template}
          ```
        MARKDOWN
      end
    end
  end
end
