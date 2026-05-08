# frozen_string_literal: true

module SkillBench
  # Registry of provider configuration schemas with default placeholder values.
  # Each provider defines its required configuration keys and sensible defaults.
  class ProviderSchemas
    PROVIDER_SCHEMAS = {
      openai: {
        api_key: nil,
        model: 'gpt-4o'
      },
      anthropic: {
        api_key: nil,
        model: 'claude-sonnet-4-20250514'
      },
      gemini: {
        api_key: nil,
        model: 'gemini-1.5-flash-latest',
        location: 'us-central1',
        project_id: nil
      },
      ollama: {
        api_key: nil,
        model: 'qwen:7b',
        base_url: nil
      },
      azure: {
        api_key: nil,
        model: 'gpt-4',
        endpoint: nil,
        api_version: nil
      },
      groq: {
        api_key: nil,
        model: 'llama-3.3-70b-versatile'
      },
      deepseek: {
        api_key: nil,
        model: 'deepseek-chat'
      },
      opencode: {
        api_key: nil,
        model: 'opencode-model'
      }
    }.freeze

    # Returns the configuration schema for a given provider.
    #
    # @param provider [Symbol] Provider name
    # @return [Hash] Provider configuration schema with placeholder values
    # @raise [ArgumentError] if provider is not registered
    def self.for(provider)
      PROVIDER_SCHEMAS.fetch(provider) do
        raise(ArgumentError, "Unknown provider: #{provider}. Available: #{PROVIDER_SCHEMAS.keys.join(', ')}")
      end
    end

    # Returns list of all registered provider names.
    #
    # @return [Array<Symbol>] Provider names
    def self.names
      PROVIDER_SCHEMAS.keys
    end
  end
end
