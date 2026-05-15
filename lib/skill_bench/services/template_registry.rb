# frozen_string_literal: true

require 'json'

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
      # Supported template types.
      TEMPLATE_TYPES = %i[task_md criteria_json skill_md].freeze

      # Supported category identifiers.
      CATEGORIES = %i[
        crud api background_job controller model
        migration concern policy form_object view_component
      ].freeze

      # Category-specific requirements for task templates.
      CATEGORY_REQUIREMENTS = {
        crud: "- Implement Create, Read, Update, Delete operations\n- Use Service Object pattern with `.call`\n- Include input validation",
        api: "- Implement API client with proper error handling\n- Use Faraday or Net::HTTP\n- Handle authentication and retries",
        background_job: "- Implement as an ActiveJob or Sidekiq worker\n- Include retry logic and error handling\n- Ensure idempotency",
        controller: "- Follow RESTful conventions\n- Use strong parameters\n- Include proper error responses",
        model: "- Define validations and associations\n- Add scopes for common queries\n- Include callback hooks where appropriate",
        migration: "- Write reversible migration\n- Include index definitions\n- Handle data migration if needed",
        concern: "- Extract shared behavior into a module\n- Use ActiveSupport::Concern\n- Keep interface minimal",
        policy: "- Implement authorization checks\n- Follow Pundit or similar patterns\n- Cover all CRUD actions",
        form_object: "- Encapsulate form logic outside the model\n- Include ActiveModel validations\n- Handle nested attributes",
        view_component: "- Create a reusable view component\n- Include preview support\n- Add unit tests for rendering"
      }.freeze

      # Category-specific scoring criteria.
      CATEGORY_CRITERIA = {
        crud: { focus: 'data integrity', required_tests: %w[create read update delete] },
        api: { focus: 'error handling', required_tests: %w[success failure timeout] },
        background_job: { focus: 'reliability', required_tests: %w[perform retry failure] },
        controller: { focus: 'REST compliance', required_tests: %w[index show create update destroy] },
        model: { focus: 'data modeling', required_tests: %w[validations associations scopes] },
        migration: { focus: 'reversibility', required_tests: %w[up down] },
        concern: { focus: 'reusability', required_tests: %w[inclusion behavior] },
        policy: { focus: 'authorization', required_tests: %w[permitted denied] },
        form_object: { focus: 'validation', required_tests: %w[valid invalid submit] },
        view_component: { focus: 'rendering', required_tests: %w[render slots preview] }
      }.freeze

      # Category pattern descriptions for skill templates.
      CATEGORY_PATTERNS = {
        crud: 'Service Object implementing Create, Read, Update, Delete operations.',
        api: 'Layered API client with Auth, Client, Fetcher, Builder, and Entity layers.',
        background_job: 'Background job with retry logic, error handling, and idempotency.',
        controller: 'RESTful controller with strong parameters and proper error responses.',
        model: 'ActiveRecord model with validations, associations, and scopes.',
        migration: 'Reversible database migration with indexes and data handling.',
        concern: 'ActiveSupport::Concern extracting shared behavior.',
        policy: 'Authorization policy covering all CRUD actions.',
        form_object: 'Form object encapsulating validation and persistence logic.',
        view_component: 'Reusable view component with previews and unit tests.'
      }.freeze

      # Category code templates for skill templates.
      CATEGORY_CODE_TEMPLATES = {
        crud: "class {{skill_name}}\n  def self.call(params)\n    new(params).call\n  end\nend",
        api: "class {{skill_name}}\n  def self.call(endpoint, params = {})\n    new(endpoint, params).call\n  end\nend",
        background_job: "class {{skill_name}} < ApplicationJob\n  def perform(*args)\n    # job logic\n  end\nend",
        controller: "class {{skill_name}}Controller < ApplicationController\n  def index; end\n  def show; end\nend",
        model: "class {{skill_name}} < ApplicationRecord\n  validates :name, presence: true\nend",
        migration: "class {{skill_name}} < ActiveRecord::Migration[7.1]\n  def change\n    # migration logic\n  end\nend",
        concern: "module {{skill_name}}\n  extend ActiveSupport::Concern\nend",
        policy: "class {{skill_name}}Policy\n  def initialize(user, record)\n    @user = user\n    @record = record\n  end\nend",
        form_object: "class {{skill_name}}\n  include ActiveModel::Model\n  include ActiveModel::Attributes\nend",
        view_component: "class {{skill_name}} < ViewComponent::Base\n  def initialize(title:)\n    @title = title\n  end\nend"
      }.freeze

      # Resolves a template by type and category, optionally interpolating variables.
      #
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

        template = fetch_template
        interpolate(template)
      end

      private

      attr_reader :template_type, :category, :variables

      # Validates that the template type is supported.
      #
      # @raise [ArgumentError] if the template type is not in {TEMPLATE_TYPES}
      # @return [void]
      def validate_template_type!
        return if TEMPLATE_TYPES.include?(template_type)

        raise ArgumentError, "Invalid template type: #{template_type}. Valid types: #{TEMPLATE_TYPES.join(', ')}"
      end

      # Validates that the category is supported.
      #
      # @raise [ArgumentError] if the category is not in {CATEGORIES}
      # @return [void]
      def validate_category!
        return if CATEGORIES.include?(category)

        raise ArgumentError, "Invalid category: #{category}. Valid categories: #{CATEGORIES.join(', ')}"
      end

      # Fetches the raw template string for the current type and category.
      #
      # @return [String] The raw template content
      def fetch_template
        send(:"build_#{template_type}")
      end

      # Replaces +{{key}}+ placeholders with corresponding variable values.
      #
      # @param template [String] The raw template with placeholders
      # @return [String] The interpolated template
      def interpolate(template)
        result = template.dup
        variables.each do |key, value|
          result.gsub!("{{#{key}}}", value.to_s)
        end
        result
      end

      # Builds a task Markdown template for the current category.
      #
      # @return [String] Task description in Markdown
      def build_task_md
        <<~MARKDOWN
          # Task: Implement {{skill_name}} (#{category})

          ## Objective

          Implement a #{category_label} following Rails best practices and the project's established patterns.

          ## Requirements

          #{category_requirements}

          ## Acceptance Criteria

          - All tests pass (`bundle exec rake test`)
          - Code follows project conventions
          - YARD documentation for all public methods
          - No rubocop or reek offenses
        MARKDOWN
      end

      # Builds a criteria JSON template for the current category.
      #
      # @return [String] Scoring criteria in JSON format
      def build_criteria_json
        criteria = {
          category: category.to_s,
          dimensions: [
            { name: 'correctness', weight: 30, pass_threshold: 70 },
            { name: 'adherence', weight: 25, pass_threshold: 60 },
            { name: 'quality', weight: 20, pass_threshold: 60 },
            { name: 'tests', weight: 15, pass_threshold: 80 },
            { name: 'docs', weight: 10, pass_threshold: 50 }
          ],
          minimum_delta: 5,
          category_specific: category_criteria
        }

        JSON.pretty_generate(criteria)
      end

      # Builds a skill Markdown template for the current category.
      #
      # @return [String] Skill instructions in Markdown
      def build_skill_md
        <<~MARKDOWN
          # Skill: {{skill_name}} (#{category})

          ## Pattern

          #{category_pattern}

          ## Hard Rules

          1. Follow TDD — write failing test first, then implement.
          2. Use `.call` class method as entry point (Service Object pattern).
          3. Each class has one responsibility (SRP).
          4. YARD documentation on all public methods.
          5. `rubocop -A` and `reek` must pass.

          ## Template

          ```ruby
          #{category_code_template}
          ```
        MARKDOWN
      end

      # Returns a human-readable label for the current category.
      #
      # @return [String] Category display label
      def category_label
        category.to_s.tr('_', ' ')
      end

      # Returns category-specific requirements for the task template.
      #
      # @return [String] Markdown-formatted requirements
      def category_requirements
        CATEGORY_REQUIREMENTS.fetch(category)
      end

      # Returns category-specific scoring criteria.
      #
      # @return [Hash] Criteria hash for the category
      def category_criteria
        CATEGORY_CRITERIA.fetch(category)
      end

      # Returns the pattern description for the skill template.
      #
      # @return [String] Pattern description
      def category_pattern
        CATEGORY_PATTERNS.fetch(category)
      end

      # Returns a code template for the skill template.
      #
      # @return [String] Ruby code snippet
      def category_code_template
        CATEGORY_CODE_TEMPLATES.fetch(category)
      end
    end
  end
end
