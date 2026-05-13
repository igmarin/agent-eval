# Task Subsystem

Manages individual evaluation tasks.

## Components

| File | Class | Purpose |
|------|-------|---------|
| `evaluator.rb` | `Task::Evaluator` | Orchestrates baseline + context runs + judge scoring |
| `file_reader.rb` | `Task::FileReader` | Safely reads task.md and criteria.json |

## Usage

```ruby
result = SkillBench::Task::Evaluator.new(task_dir:).call
```
