# frozen_string_literal: true

require 'test_helper'
require_relative '../../../../lib/clients/providers/azure_openai'

class AzureOpenAITest < Minitest::Test
  def test_base_url_uses_configured_endpoint
    Evaluator::Config.setup do |config|
      config.set_provider_api_key(:azure, 'test-key')
      config.set_provider_model(:azure, 'gpt-4')
      config.set_provider_endpoint(:azure, 'https://my-resource.openai.azure.com')
    end

    provider = Evaluator::Clients::Providers::AzureOpenAI.new(
      system_prompt: 'test',
      messages: []
    )

    assert_equal 'https://my-resource.openai.azure.com', provider.send(:base_url)
  ensure
    Evaluator::Config.reset
  end

  def test_base_url_uses_env_variable
    ENV['AZURE_OPENAI_ENDPOINT'] = 'https://env-endpoint.openai.azure.com'
    Evaluator::Config.setup do |config|
      config.set_provider_api_key(:azure, 'test-key')
      config.set_provider_model(:azure, 'gpt-4')
    end

    provider = Evaluator::Clients::Providers::AzureOpenAI.new(
      system_prompt: 'test',
      messages: []
    )

    assert_equal 'https://env-endpoint.openai.azure.com', provider.send(:base_url)
  ensure
    ENV.delete('AZURE_OPENAI_ENDPOINT')
    Evaluator::Config.reset
  end

  def test_base_url_defaults_to_placeholder
    Evaluator::Config.setup do |config|
      config.set_provider_api_key(:azure, 'test-key')
      config.set_provider_model(:azure, 'gpt-4')
    end

    provider = Evaluator::Clients::Providers::AzureOpenAI.new(
      system_prompt: 'test',
      messages: []
    )

    assert_equal 'https://<your-resource>.openai.azure.com', provider.send(:base_url)
  ensure
    Evaluator::Config.reset
  end

  def test_request_path_includes_deployment
    Evaluator::Config.setup do |config|
      config.set_provider_api_key(:azure, 'test-key')
      config.set_provider_model(:azure, 'gpt-4o')
    end

    provider = Evaluator::Clients::Providers::AzureOpenAI.new(
      system_prompt: 'test',
      messages: []
    )

    assert_equal '/openai/deployments/gpt-4o/chat/completions?api-version=2024-02-15-preview', provider.send(:request_path)
  ensure
    Evaluator::Config.reset
  end

  def test_request_headers_include_api_key
    Evaluator::Config.setup do |config|
      config.set_provider_api_key(:azure, 'test-api-key')
      config.set_provider_model(:azure, 'gpt-4')
      config.current_llm_provider = :azure
    end

    provider = Evaluator::Clients::Providers::AzureOpenAI.new(
      system_prompt: 'test',
      messages: []
    )

    headers = provider.send(:request_headers)

    assert_equal 'application/json', headers['Content-Type']
    assert_equal 'test-api-key', headers['api-key']
    refute headers.key?('Authorization')
  end

  def test_valid_config_with_all_settings
    Evaluator::Config.setup do |config|
      config.set_provider_api_key(:azure, 'test-key')
      config.set_provider_model(:azure, 'gpt-4')
      config.current_llm_provider = :azure
    end

    provider = Evaluator::Clients::Providers::AzureOpenAI.new(
      system_prompt: 'test',
      messages: []
    )

    assert provider.send(:valid_config?)
  ensure
    Evaluator::Config.reset
  end

  def test_valid_config_missing_api_key
    Evaluator::Config.setup do |config|
      config.set_provider_model(:azure, 'gpt-4')
      config.current_llm_provider = :azure
    end

    provider = Evaluator::Clients::Providers::AzureOpenAI.new(
      system_prompt: 'test',
      messages: []
    )

    refute provider.send(:valid_config?)
  end

  def test_config_error_returns_structured_response
    Evaluator::Config.reset

    provider = Evaluator::Clients::Providers::AzureOpenAI.new(
      system_prompt: 'test',
      messages: []
    )

    result = provider.send(:config_error)

    refute result[:success]
    assert_match(/API_KEY/, result[:response][:error][:message])
  end
end
