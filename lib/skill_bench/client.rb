# frozen_string_literal: true

require_relative 'clients/all'

module SkillBench
  # Facade for calling LLM clients.
  # Delegates to the configured provider.
  class Client
    # Calls the configured LLM provider with the given parameters.
    #
    # @param system_prompt [String] System prompt for the LLM
    # @param messages [Array<Hash>] Conversation messages
    # @param options [Hash] Provider-specific options
    # @return [Hash] Response from the LLM
    def self.call(system_prompt:, messages:, **options)
      provider = Config.current_llm_provider || :openai
      client_class = Clients::ProviderRegistry.for(provider)
      client_class.call(system_prompt: system_prompt, messages: messages, **options)
    end
  end
end
