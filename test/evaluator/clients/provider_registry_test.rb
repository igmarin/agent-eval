# frozen_string_literal: true

require 'test_helper'

class ProviderRegistryTest < Minitest::Test
  def setup
    # Save original registry state
    @original_providers = SkillBench::Clients::ProviderRegistry.instance_variable_get(:@providers).dup
    # Clear the registry for test isolation
    SkillBench::Clients::ProviderRegistry.instance_variable_set(:@providers, {})
  end

  def teardown
    # Restore original registry state
    SkillBench::Clients::ProviderRegistry.instance_variable_set(:@providers, @original_providers)
  end

  def test_register_and_for
    # Create a dummy class
    dummy_class = Class.new

    SkillBench::Clients::ProviderRegistry.register(:test_provider, dummy_class)

    assert_equal dummy_class, SkillBench::Clients::ProviderRegistry.for(:test_provider)
  end

  def test_for_returns_null_client_for_unknown_provider
    result = SkillBench::Clients::ProviderRegistry.for(:nonexistent)

    assert_equal SkillBench::Clients::Providers::NullClient, result
  end

  def test_providers_returns_hash
    result = SkillBench::Clients::ProviderRegistry.providers

    assert_instance_of Hash, result
  end

  def test_multiple_providers
    class1 = Class.new
    class2 = Class.new

    SkillBench::Clients::ProviderRegistry.register(:provider1, class1)
    SkillBench::Clients::ProviderRegistry.register(:provider2, class2)

    assert_equal class1, SkillBench::Clients::ProviderRegistry.for(:provider1)
    assert_equal class2, SkillBench::Clients::ProviderRegistry.for(:provider2)
  end
end
