# Evaluation Orchestration

Manages evaluation workflows across multiple tasks.

## Components

| File | Class | Purpose |
|------|-------|---------|
| `runner.rb` | `Evaluation::Runner` | Runs evaluations across multiple task directories |
| `generator.rb` | `Evaluation::Generator` | Generates evals from skills using LLM |

## Usage

```ruby
# Run evaluation
SkillBench::Evaluation::Runner.new(evals: ['my-eval'], skills: ['my-skill']).call

# Generate eval
SkillBench::Evaluation::Generator.new(skill_name:, eval_name:).call
```
