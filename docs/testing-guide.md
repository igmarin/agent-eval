# Testing Guide: Evaluations & Workflows

This guide explains how to run evaluations and how to create new evaluation tasks for skills and workflows.

## Running Evaluations

The primary tool for running evaluations is the `agent-eval` CLI.

### Basic Usage

To run a specific evaluation task:

```bash
bundle exec agent-eval run my-eval --skill=my-skill --provider=openai
```

### Output Formats

**Human-readable (default):**
```
============================================================
Eval: my-eval
Skill: my-skill
Provider: openai
Status: PASSED
Score: 0.95
============================================================
```

**JSON (CI mode):**
```bash
bundle exec agent-eval run my-eval --skill=my-skill --provider=openai --ci
```

**JUnit XML:**
```bash
bundle exec agent-eval run my-eval --skill=my-skill --provider=openai --format=junit
```

### Batch Processing

To run all evaluations within a directory:

```bash
bundle exec agent-eval run evals/skills --skill=my-skill --provider=openai
```

The evaluator will recursively find all task directories and execute them.

### Overriding Skill Context

By default, the evaluator infers the skill path from the evaluation path. If you need to test an evaluation against a different skill:

```bash
bin/evaluate --eval ../private-evals/skills/patterns/ruby-service-objects/call-pattern-and-response-format --skill ../skills/custom-skill
```

## Creating New Evaluations

An evaluation task consists of a directory containing at least two files: `task.md` and `criteria.json`.

### 1. The Task (`task.md`)

This file contains the instructions for the AI agent. It should describe a specific problem to solve or a feature to implement.

**Best Practices:**
- Provide clear context and requirements.
- Include a description of the current codebase state.
- Specify the desired outcome.

### 2. The Criteria (`criteria.json`)

This file defines the grading rubric used by the LLM Judge.

```json
[
  {
    "name": "Standard usage",
    "description": "The solution implements the .call pattern as specified in the skill.",
    "max_score": 50
  },
  {
    "name": "Error handling",
    "description": "The solution includes appropriate error handling and logging.",
    "max_score": 50
  }
]
```

**Fields:**
- `name`: A short label for the criterion.
- `description`: Detailed explanation of what the judge should look for.
- `max_score`: The maximum points awarded for this criterion (usually summing to 100).
- `conditional` (optional): If `true`, the judge will treat this as an N/A-safe rule.

## Evaluating Workflows vs. Skills

### Atomic Skills

Skills are isolated blocks of logic (e.g., a specific API pattern). Evaluations for skills should focus strictly on the adherence to the patterns defined in the skill's `SKILL.md`.

### Workflows

Workflows are sequences of skills or complex orchestrations (e.g., the full TDD loop). Evaluations for workflows should focus on the process, the ordering of tasks, and the successful completion of a multi-step objective.

When running a workflow evaluation, ensure the `--eval` path points to a workflow eval directory such as `evals/workflows/`.

## Running the Test Suite

The project uses Minitest with 326+ tests covering:
- Core evaluation engine (`test/evaluator/`)
- CLI commands and models (`test/agent_eval/`)
- Provider clients (`test/evaluator/clients/`)
- Skill services (`test/skills/`)

```bash
# Run all tests
bundle exec rake test

# Run with coverage report
bundle exec rake test COVERAGE=true

# Run specific test file
bundle exec ruby -Itest test/agent_eval/commands/skill_new_test.rb

# Run tests matching a pattern
bundle exec ruby -Itest -e "Dir['test/**/*_test.rb'].each { |f| require f }" -- --name /provider/
```

### Test Isolation

Tests use temporary directories and restore the original working directory:
```ruby
def setup
  @original_dir = Dir.pwd
  @tmp_dir = Dir.mktmpdir('test')
  Dir.chdir(@tmp_dir)
end

def teardown
  Dir.chdir(@original_dir)
  FileUtils.rm_rf(@tmp_dir)
end
```

### Environment Variable Handling

Tests that modify ENV must restore original values:
```ruby
def test_something
  original_key = ENV.fetch('OPENAI_API_KEY', nil)
  ENV.delete('OPENAI_API_KEY')
  # ... test code ...
ensure
  ENV['OPENAI_API_KEY'] = original_key if original_key
end
```
