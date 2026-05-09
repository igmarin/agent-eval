# SkillBench - 5 Minute First Eval Guide

Get started with Ruby Skill Bench in 5 minutes.

## Prerequisites

- Ruby 3.1+
- Bundler

## Step 1: Installation

Add to your Gemfile:

```ruby
gem 'ruby-skill-bench'
```

Or install globally:

```bash
gem install ruby-skill-bench
```

## Step 2: Initialize Configuration

```bash
skill-bench init --openai
```

This creates `skill-bench.json` with the OpenAI provider config. Use `--force` to overwrite.

**Available providers:** `--openai`, `--anthropic`, `--gemini`, `--ollama`, `--azure`, `--groq`, `--deepseek`, `--opencode`

## Step 3: Create Your First Skill

```bash
skill-bench skill new my-service --mode=rails --template=service_object
```

This creates `skills/my-service/SKILL.md` with a Rails service object template.

## Step 4: Create an Eval

You have two options.

### Option A — Manual (recommended for learning)

```bash
skill-bench eval new my-first-eval --runtime=rails
```

**Creates:**

```bash
evals/
└── my-first-eval/
    ├── task.md           # <- The prompt given to the agent
    └── criteria.json     # <- How the judge scores the result
```

#### What goes in `task.md`

This is the **user prompt** the agent receives. Be specific — the agent has no other context.

**Bad example (too vague):**

```markdown
Create a user service.
```

**Good example (specific requirements):**

```markdown
Create a `UserRegistrationService` that:

1. Accepts `email` and `password` parameters
2. Validates email format with a regex (must contain @ and a domain)
3. Validates password length (minimum 8 characters)
4. Returns `{ success: true, response: { user_id: ... } }` on success
5. Returns `{ success: false, response: { error: { message: ... } } }` on failure
6. Includes YARD documentation for every public method
7. Includes RSpec tests covering both success and failure paths
8. Follows the frozen_string_literal convention

Do not use ActiveRecord. Use plain Ruby objects.
```

#### What goes in `criteria.json`

This tells the judge how to score. The 5 core dimensions are mandatory.

**Minimal example (copy-paste ready):**

```json
{
  "context": "Evaluate service object creation skill",
  "dimensions": [
    { "name": "correctness", "max_score": 30 },
    { "name": "skill_adherence", "max_score": 25 },
    { "name": "code_quality", "max_score": 20 },
    { "name": "test_coverage", "max_score": 15 },
    { "name": "documentation", "max_score": 10 }
  ],
  "pass_threshold": 70,
  "minimum_delta": 10
}
```

**With custom descriptions (recommended):**

```json
{
  "context": "Evaluate service object creation skill",
  "dimensions": [
    { "name": "correctness", "max_score": 30 },
    { "name": "skill_adherence", "max_score": 25, "description": "Did the agent use the .call pattern and return the standardized hash?" },
    { "name": "code_quality", "max_score": 20 },
    { "name": "test_coverage", "max_score": 15, "description": "Are there tests for both success and failure paths?" },
    { "name": "documentation", "max_score": 10 }
  ],
  "pass_threshold": 70,
  "minimum_delta": 10
}
```

**Key rules:**

- `max_score` values must sum to exactly 100
- All 5 core dimensions (`correctness`, `skill_adherence`, `code_quality`, `test_coverage`, `documentation`) are required
- `pass_threshold` = minimum context score to pass (0-100)
- `minimum_delta` = minimum improvement over baseline to pass

---

### Option B — Auto-Generated (from a skill)

If you already have a skill and want the LLM to design the eval for you:

```bash
skill-bench eval generate my-service --name my-first-eval
```

This reads `skills/my-service/SKILL.md` and generates both `task.md` and `criteria.json`. The output is immediately validated — if the generated `criteria.json` has invalid dimensions or doesn't sum to 100, you'll see an error and can fix it manually.

---

## Step 5: Run the Eval

```bash
skill-bench run my-first-eval --skill=my-service
```

Provider is read from `skill-bench.json` — no `--provider` flag needed.

**What happens behind the scenes:**

1. Agent runs **without** skill context → produces baseline output
2. Agent runs **with** skill context → produces context output
3. Judge scores both independently → per-dimension scores
4. Engine computes deltas → applies pass/fail logic
5. Result is recorded in `.skill-bench-history.json` for trend tracking

**Run with multiple skills:**

```bash
skill-bench run my-first-eval --skill=skill-a --skill=skill-b
```

Both skill contexts are concatenated. The judge evaluates whether the combined context improves results.

**Available Providers (configured via `skill-bench init`):**

- `openai` — OpenAI GPT models
- `anthropic` — Anthropic Claude
- `gemini` — Google Gemini
- `azure` — Azure OpenAI
- `ollama` — Local Ollama models
- `groq` — Groq fast inference
- `deepseek` — DeepSeek models
- `opencode` — OpenCode platform

## Step 6: Check Results

**Human-readable output (default):**

```text
═══════════════════════════════════════════════════════
  Eval: my-first-eval
  Skill: my-service
  Provider: openai
═══════════════════════════════════════════════════════

  DIMENSION                BASELINE   CONTEXT    DELTA
  ──────────────────────── ───────── ───────── ───────
  Correctness (30)                12        28     +16
  Skill Adherence (25)             5        22     +17
  Code Quality (20)               10        16      +6
  Test Coverage (15)               3        13     +10
  Documentation (10)               2         8      +6
  ──────────────────────── ───────── ───────── ───────
  TOTAL                          32/100    87/100   +55

  TREND: baseline ↑ (+2), context ↑ (+7)
  VERDICT: PASS (threshold: 70, minimum delta: 10)
═══════════════════════════════════════════════════════
```

**Column meanings:**

- **BASELINE:** Score without skill (unaided performance)
- **CONTEXT:** Score with skill (aided performance)
- **DELTA:** Improvement = CONTEXT - BASELINE
- **TREND:** Change since last run (from `.skill-bench-history.json`)
- **VERDICT:** PASS only if CONTEXT >= threshold AND DELTA >= minimum_delta

**JSON output:**

```bash
skill-bench run my-first-eval --skill=my-service --format json
```

**JUnit XML output:**

```bash
skill-bench run my-first-eval --skill=my-service --format junit
```

## Troubleshooting

### "Dimension max_scores must sum to 100"

Check your `criteria.json`. All `max_score` values must add up to exactly 100.

### "missing required core dimensions: documentation"

You are missing one of the 5 mandatory dimensions. All of these must be present: `correctness`, `skill_adherence`, `code_quality`, `test_coverage`, `documentation`.

### "Config load failed, using mock provider"

Run `skill-bench init --<provider>` to create `skill-bench.json`, or ensure it exists in the current directory.

### "Baseline agent failed" or "Context agent failed"

The LLM provider returned an error. Check your API key in `skill-bench.json` or environment variables.

## Next Steps

- Explore skill templates with `skill-bench skill new --help`
- Read `docs/architecture.md` for the full component map
- Read `docs/testing-guide.md` for advanced eval authoring techniques