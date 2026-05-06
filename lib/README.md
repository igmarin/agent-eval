# Evaluator Core (`lib`)

This directory contains the core logic for the AI Agent Evaluation System.

## Architecture Overview

The system is built around several decoupled domains to ensure maintainability and separation of concerns:

- **`clients/`**: LLM provider integrations via Faraday.
  - **`base_client.rb`**: Abstract base implementing Template Method pattern for all providers.
  - **`provider_registry.rb`**: Extensible registry for provider lookup (replaces case statements).
  - **`providers/openai.rb`**: OpenAI API client.
  - **`providers/gemini.rb`**: Google Gemini client with location/project configuration.
  - **`providers/ollama.rb`**: Local Ollama client (OpenAI-compatible API).
  - **`providers/anthropic.rb`**: Anthropic Claude client using Messages API.
  - **`providers/null_client.rb`**: Null Object pattern for unsupported providers.
- **`SourcePathResolver`**: Infers the source skill or workflow directory from an eval target, while still allowing explicit overrides. See [evaluator/README.md](evaluator/README.md).
- **`ContextHydrator`**: Injects necessary context into the prompt, mapping source markdown files to XML blocks.
- **`ReactAgent`** (in `lib/react_agent`): Implements the ReAct (Reasoning and Acting) loop. See [react_agent/README.md](react_agent/README.md).
- **`Evaluator`** (in `lib/evaluator`): Manages the testing sandbox and the final evaluation (Judge) logic. See [evaluator/README.md](evaluator/README.md).
- **`Tools`** (in `lib/tools`): Actionable capabilities the agent can use to interact with its environment. See [tools/README.md](tools/README.md).
- **`Runner`**: The central orchestrator that glues these components together to execute a skill evaluation.
  - Now uses `TaskEvaluator` for individual task evaluation.
  - Uses `TaskFileReader` for safe file I/O with error handling.

## Design Philosophy

- **Service Objects (POODR / Sandi Metz):** The code aims for the Single Responsibility Principle. Complex loops (like ReAct) are broken down into discrete objects like `Step` and `ToolExecutor`.
- **Statelessness:** State is mostly kept in the message history passed back and forth, allowing components to remain pure and stateless where possible.
- **Security First:** Actions interacting with the OS (like `tools`) validate boundaries before execution.
- **Registry Pattern:** Providers are registered dynamically via `ProviderRegistry` for extensibility.
