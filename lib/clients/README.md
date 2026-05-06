# LLM Clients (`lib/clients`)

This directory contains LLM provider integrations for the Evaluator system.

## Architecture

### Base Client (`base_client.rb`)

Abstract base class implementing the **Template Method pattern**:
- Defines the algorithm: `call` → `valid_config?` → `execute_request` → `handle_response`
- Subclasses override: `base_url`, `request_path`, `request_headers`, `valid_config?`, `config_error`
- Common Faraday setup with timeout handling and JSON parsing
- Standardized response contract: `{ success: bool, response: { ... } }`

**Key methods:**
- `self.call(system_prompt:, messages:, tools: [])` - Entry point with `@raise` tags for Faraday errors
- `execute_request` - Sets up Faraday connection and POSTs to provider
- `extract_message(body)` - Provider-specific message extraction (override in subclasses)

### Provider Registry (`provider_registry.rb`)

Extensible registry for provider lookup (replaces hard-coded case statements):

```ruby
# Register a provider
Evaluator::Clients::ProviderRegistry.register(:openai, Evaluator::Clients::Providers::OpenAI)

# Look up a provider
provider_class = Evaluator::Clients::ProviderRegistry.for(:openai)
# Returns NullClient if not found
```

**Adding a new provider:**
1. Create `providers/your_provider.rb` inheriting from `BaseClient`
2. Implement required template methods
3. Add `Evaluator::Clients::ProviderRegistry.register(:your_provider, self)` in class body
4. Add `require_relative 'clients/providers/your_provider'` to `client.rb`

## Providers

### OpenAI (`providers/openai.rb`)
- **Base URL**: `https://api.openai.com`
- **Endpoint**: `/v1/chat/completions`
- **Config**: `api_key`, `model` (default: `gpt-4o`)
- **Registry name**: `:openai`

### Gemini (`providers/gemini.rb`)
- **Base URL**: `https://{location}-aiplatform.googleapis.com`
- **Endpoint**: `/v1/projects/{project_id}/locations/{location}/endpoints/openapi/chat/completions`
- **Config**: `api_key`, `model`, `location`, `project_id`
- **Registry name**: `:gemini`

### Ollama (`providers/ollama.rb`)
- **Base URL**: `http://localhost:11434` (configurable via `OLLAMA_BASE_URL` env var or config)
- **Endpoint**: `/v1/chat/completions` (OpenAI-compatible)
- **Config**: `model` (default: `qwen:7b`), optional `api_key` for Bearer auth
- **Registry name**: `:ollama`
- **Note**: Does not require API key by default

### Anthropic Claude (`providers/anthropic.rb`)
- **Base URL**: `https://api.anthropic.com`
- **Endpoint**: `/v1/messages`
- **Config**: `api_key`, `model`, `max_tokens` (default: 4096)
- **Headers**: `x-api-key`, `anthropic-version: 2023-06-01`
- **Registry name**: `:anthropic`

### NullClient (`providers/null_client.rb`)
- **Purpose**: Null Object pattern for unsupported providers
- **Behavior**: Always returns config error with provider name
- **Note**: Extends `BaseClient` for interface consistency

## Response Contract

All providers return standardized responses:

```ruby
# Success
{ success: true, response: { message: { 'content' => '...' } } }

# Error
{ success: false, response: { error: { message: '...' } } }
```

## Error Handling

- Faraday connection errors are rescued and returned as structured errors
- Provider-specific validation via `valid_config?` and `config_error`
- All errors logged with message AND backtrace (per coding standards)
