# frozen_string_literal: true

module SkillBench
  module Services
    class TemplateRegistry
      # Value object holding all template data for a single category.
      CategoryData = Data.define(:requirements, :criteria, :pattern, :code_template)

      REGISTRY = {
        crud: CategoryData.new(
          requirements: "- Implement Create, Read, Update, Delete operations\n- Use Service Object pattern with `.call`\n- Include input validation",
          criteria: { focus: 'data integrity', required_tests: %w[create read update delete] },
          pattern: 'Service Object implementing Create, Read, Update, Delete operations.',
          code_template: "class {{skill_name}}\n  def self.call(params)\n    new(params).call\n  end\nend"
        ),
        api: CategoryData.new(
          requirements: "- Implement API client with proper error handling\n- Use Faraday or Net::HTTP\n- Handle authentication and retries",
          criteria: { focus: 'error handling', required_tests: %w[success failure timeout] },
          pattern: 'Layered API client with Auth, Client, Fetcher, Builder, and Entity layers.',
          code_template: "class {{skill_name}}\n  def self.call(endpoint, params = {})\n    new(endpoint, params).call\n  end\nend"
        ),
        background_job: CategoryData.new(
          requirements: "- Implement as an ActiveJob or Sidekiq worker\n- Include retry logic and error handling\n- Ensure idempotency",
          criteria: { focus: 'reliability', required_tests: %w[perform retry failure] },
          pattern: 'Background job with retry logic, error handling, and idempotency.',
          code_template: "class {{skill_name}} < ApplicationJob\n  def perform(*args)\n    # job logic\n  end\nend"
        ),
        controller: CategoryData.new(
          requirements: "- Follow RESTful conventions\n- Use strong parameters\n- Include proper error responses",
          criteria: { focus: 'REST compliance', required_tests: %w[index show create update destroy] },
          pattern: 'RESTful controller with strong parameters and proper error responses.',
          code_template: "class {{skill_name}}Controller < ApplicationController\n  def index; end\n  def show; end\nend"
        ),
        model: CategoryData.new(
          requirements: "- Define validations and associations\n- Add scopes for common queries\n- Include callback hooks where appropriate",
          criteria: { focus: 'data modeling', required_tests: %w[validations associations scopes] },
          pattern: 'ActiveRecord model with validations, associations, and scopes.',
          code_template: "class {{skill_name}} < ApplicationRecord\n  validates :name, presence: true\nend"
        ),
        migration: CategoryData.new(
          requirements: "- Write reversible migration\n- Include index definitions\n- Handle data migration if needed",
          criteria: { focus: 'reversibility', required_tests: %w[up down] },
          pattern: 'Reversible database migration with indexes and data handling.',
          code_template: "class {{skill_name}} < ActiveRecord::Migration[7.1]\n  def change\n    # migration logic\n  end\nend"
        ),
        concern: CategoryData.new(
          requirements: "- Extract shared behavior into a module\n- Use ActiveSupport::Concern\n- Keep interface minimal",
          criteria: { focus: 'reusability', required_tests: %w[inclusion behavior] },
          pattern: 'ActiveSupport::Concern extracting shared behavior.',
          code_template: "module {{skill_name}}\n  extend ActiveSupport::Concern\nend"
        ),
        policy: CategoryData.new(
          requirements: "- Implement authorization checks\n- Follow Pundit or similar patterns\n- Cover all CRUD actions",
          criteria: { focus: 'authorization', required_tests: %w[permitted denied] },
          pattern: 'Authorization policy covering all CRUD actions.',
          code_template: "class {{skill_name}}Policy\n  def initialize(user, record)\n    @user = user\n    @record = record\n  end\nend"
        ),
        form_object: CategoryData.new(
          requirements: "- Encapsulate form logic outside the model\n- Include ActiveModel validations\n- Handle nested attributes",
          criteria: { focus: 'validation', required_tests: %w[valid invalid submit] },
          pattern: 'Form object encapsulating validation and persistence logic.',
          code_template: "class {{skill_name}}\n  include ActiveModel::Model\n  include ActiveModel::Attributes\nend"
        ),
        view_component: CategoryData.new(
          requirements: "- Create a reusable view component\n- Include preview support\n- Add unit tests for rendering",
          criteria: { focus: 'rendering', required_tests: %w[render slots preview] },
          pattern: 'Reusable view component with previews and unit tests.',
          code_template: "class {{skill_name}} < ViewComponent::Base\n  def initialize(title:)\n    @title = title\n  end\nend"
        )
      }.freeze
    end
  end
end
