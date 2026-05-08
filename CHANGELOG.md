# Changelog

All notable changes to `ruby-skill-bench` will be documented in this file.

The format is based on [Keep a Changelog](https://keepachangelog.com/en/1.1.0/),
and this project adheres to [Semantic Versioning](https://semver.org/spec/v2.0.0.html).

## [Unreleased]

### Added
- `ProviderSchemas` registry for provider configuration templates (8 providers: OpenAI, Anthropic, Gemini, Azure, Ollama, Groq, DeepSeek, OpenCode)
- `SkillResolver` service for resolving skills by path or name with recursive discovery
- `Cli::InitCommand`, `Cli::RunCommand`, `Cli::SkillCommand`, `Cli::EvalCommand` — extracted CLI subcommand handlers
- `Cli::HelpPrinter`, `Cli::ResultPrinter` — extracted CLI output formatters
- `Config#to_provider` method for building Provider model from config
- `ResponseParser` now handles Array response bodies gracefully

### Changed
- **BREAKING:** `skill-bench init` now requires a provider flag (`--openai`, `--gemini`, etc.)
- **BREAKING:** Config format changed from multi-provider to single-provider: `{ "provider": "...", "max_execution_time": N, "config": {...} }`
- **BREAKING:** `skill-bench run` no longer accepts `--provider` flag — reads provider from config
- `Skill.discover` now searches recursively for nested skill directories
- `Config` model switched from YAML (`.agent-eval.yml`) to JSON (`skill-bench.json`)
- `RunnerService` reads provider from config file instead of accepting `provider_name` parameter
- CLI refactored from monolithic class (~230 lines) to thin dispatcher (~45 lines) with extracted command modules
- `print_result` checks `result[:pass]` instead of `result[:success]` for correct scoring output

### Fixed
- `ResponseParser.parse_body` no longer crashes on Array response bodies
- `RunnerService.resolve_provider` builds proper `Models::Provider` instead of raw Hash
- `ProviderRegistry.for` now receives symbol keys for correct provider lookup
- `print_result` now displays actual error messages instead of "Unknown error"
- Reek: `NestedIterators` in `handle_init` extracted to `register_provider_options`
- Reek: `FeatureEnvy` in `RunnerService#resolve_provider` moved to `Config#to_provider`
- Reek: `DuplicateMethodCall` in `print_result` eliminated with local variables
- `Config#to_provider` now returns nil when provider_name is nil (prevents malformed Provider)
- `RunnerService` memoizes `resolve_provider` to avoid double Config.load calls
- `RunnerService.mock_provider` extracted to module-level `MOCK_PROVIDER` constant Struct
- `SkillResolver.resolve_by_name` now detects and raises on duplicate skill names
- `ProviderSchemas.for` returns a dup of the schema to prevent registry mutation
- `ProviderSchemas::PROVIDER_SCHEMAS` inner hashes are now frozen (deep freeze)
- `Cli::InitCommand` error message now dynamically lists available providers
- Removed stale `require 'yaml'` from `Config` model
- Test teardown in `InitTest` and `InitProviderTest` now restores original working directory
- `SkillTest` no longer uses global `Dir.chdir` — uses absolute temp paths instead
- Added missing `require 'json'` to `RunnerServiceTest`

### Quality
- 373 tests, 0 failures
- 89.7% line coverage
- Rubocop: 0 offenses
- Reek: 0 warnings

## [0.1.0] - 2026-05-07

### Added
- Deterministic scoring engine (`ScoringService`) with composite scoring: test pass rate (50%), timing compliance (30%), error handling (20%)
- Hierarchical configuration loading: code defaults → home JSON → local JSON → environment variables
- `criteria.json` integration with configurable pass/fail thresholds
- 7 LLM providers: OpenAI, Anthropic, Gemini, Azure OpenAI, Ollama, Groq, DeepSeek
- OpenCode provider support
- 4 core CLI commands: `init`, `run`, `skill new`, `eval new`
- Rails skill templates: service object, concern, ActiveRecord model
- Git sandbox isolation for all evaluation runs
- ReAct loop with tool execution (run_command, read_file, write_file)
- LLM-powered judge for code diff evaluation
- JUnit XML output for CI/CD integration
- Benchmark history persistence with atomic writes

### Changed
- Renamed from `agent-eval` to `ruby-skill-bench`
- Merged `Evaluator::` and `AgentEval::` namespaces into `SkillBench::`
- Renamed CLI executable from `evaluate` to `skill-bench`
- Config file format from `.agent-eval.yml` to `.skill-bench.json`
- Increased LLM request timeout from 10s to 120s (configurable)
- Replaced `puts` with `warn` for debug output in ReAct loop

### Security
- Added dangerous command blocklist (27 commands including shells, interpreters, network tools)
- Path validation to prevent directory traversal in eval paths
- URL parameter sanitization with `CGI.escape` for all provider endpoints
- YAML Symbol DoS prevention (`permitted_classes: []`)
- Atomic file writes with `flock` to prevent race conditions
- `EVALUATOR_HISTORY_FILE` path validation against allowed prefixes

### Fixed
- `Config.reset` now applies full pipeline (defaults → JSON → ENV)
- Nil-safety across agent response handling
- Judge response key type mismatch (symbol vs string)
- `Dir.home` crash in container environments
- AgentRunner return type confusion in TaskEvaluator

### Quality
- 317 tests, 0 failures
- 89.9% line coverage
- Rubocop: 0 offenses
- Reek: 0 warnings
