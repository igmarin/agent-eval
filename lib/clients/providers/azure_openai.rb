# frozen_string_literal: true

require_relative '../base_client'
require_relative '../provider_registry'

module Evaluator
  module Clients
    module Providers
      # Azure OpenAI provider using the OpenAI-compatible API.
      # Requires an API key and a deployment name (model).
      class AzureOpenAI < BaseClient
        Evaluator::Clients::ProviderRegistry.register(:azure, self)

        def initialize(system_prompt:, messages:, tools: [], **options)
          super
          @endpoint = options[:endpoint] || Evaluator::Config.llm_providers_config.dig(:azure, :endpoint)
        end

        protected

        # @return [String]
        def base_url
          env_url = ENV.fetch('AZURE_OPENAI_ENDPOINT', nil)
          return env_url unless env_url.to_s.empty?

          return @endpoint.to_s unless @endpoint.to_s.empty?

          'https://<your-resource>.openai.azure.com'
        end

        # @return [String]
        def request_path
          "/openai/deployments/#{@model}/chat/completions?api-version=2024-02-15-preview"
        end

        # @return [Hash]
        def request_headers
          {
            'api-key' => @api_key,
            'Content-Type' => 'application/json'
          }
        end

        # @return [Boolean]
        def valid_config?
          !(@api_key.to_s.strip.empty? || @model.to_s.strip.empty?)
        end

        # @return [Hash]
        def config_error
          missing = []
          missing << 'API_KEY' if @api_key.to_s.strip.empty?
          missing << 'model (deployment name)' if @model.to_s.strip.empty?
          message = if missing.length > 1
                      "#{missing[0...-1].join(', ')}, and #{missing[-1]} not set for Azure OpenAI"
                    else
                      "#{missing.first} not set for Azure OpenAI"
                    end
          { success: false, response: { error: { message: message } } }
        end

        private

        # Extracts the message from Azure OpenAI's response (OpenAI-compatible format).
        #
        # @param body [Hash] The parsed JSON response body.
        # @return [Hash, nil]
        def extract_message(body)
          body.dig('choices', 0, 'message')
        end
      end
    end
  end
end
