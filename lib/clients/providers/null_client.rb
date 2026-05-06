# frozen_string_literal: true

require_relative '../base_client'

module Evaluator
  module Clients
    module Providers
      # Null Object implementation for unsupported LLM providers.
      # Extends BaseClient for interface consistency.
      class NullClient < BaseClient
        protected

        # @return [String]
        def base_url
          ''
        end

        # @return [String]
        def request_path
          ''
        end

        # :reek:UtilityFunction - implements BaseClient interface, uses Config class method intentionally
        # @return [Hash]
        def config_error
          provider = Evaluator::Config.current_llm_provider
          { success: false, response: { error: { message: "Unsupported or unconfigured LLM provider: '#{provider}'" } } }
        end

        # NullClient is never valid - always returns config error.
        # @return [false]
        def valid_config?
          false
        end
      end
    end
  end
end
