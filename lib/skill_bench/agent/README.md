# Agent Subsystem

Executes AI agents within isolated sandboxes.

## Components

| File | Class | Purpose |
|------|-------|---------|
| `runner.rb` | `Agent::Runner` | Sets up prompt, hydrates context, kicks off ReactAgent |
| `summary.rb` | `Agent::Summary` | Captures execution metadata for judge |
| `react_agent.rb` | `Agent::ReactAgent` | Public entry point for ReAct loop |

## Sub-components

`react_agent/` — ReAct loop implementation:
- `loop_runner.rb` — Main ReAct execution loop
- `step.rb` — Single ReAct step
- `tool_executor.rb` — Tool dispatch and execution
