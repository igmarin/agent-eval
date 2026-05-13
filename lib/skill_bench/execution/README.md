# Execution Environment

Provides isolated execution environments for agent evaluation.

## Components

| File | Class | Purpose |
|------|-------|---------|
| `context_hydrator.rb` | `Execution::ContextHydrator` | Loads source context and wraps in XML tags |
| `sandbox.rb` | `Execution::Sandbox` | Creates isolated tempdir with git init |
| `source_path_resolver.rb` | `Execution::SourcePathResolver` | Resolves skill paths from eval names |

## Usage

```ruby
sandbox = SkillBench::Execution::Sandbox.new(source_path:).prepare
```
