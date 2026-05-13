# Judge Subsystem

Evaluates AI-generated code modifications by calling an LLM judge.

## Components

| File | Class | Purpose |
|------|-------|---------|
| `judge.rb` | `Judge::Judge` | Orchestrates the LLM judge call |
| `prompt.rb` | `Judge::Prompt` | Builds structured prompts from task + criteria |
| `response.rb` | `Judge::Response` | Parses and validates judge JSON responses |

## Usage

```ruby
response = SkillBench::Judge::Judge.new(task:, criteria:, output:).call
```
