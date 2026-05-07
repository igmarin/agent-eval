# Changelog

All notable changes to `ruby-skill-bench` will be documented in this file.

The format is based on [Keep a Changelog](https://keepachangelog.com/en/1.1.0/),
and this project adheres to [Semantic Versioning](https://semver.org/spec/v2.0.0.html).

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
