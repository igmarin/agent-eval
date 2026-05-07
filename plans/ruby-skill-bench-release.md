# Ruby Skill Bench - Release Plan

## 🎯 Vision
A high-fidelity evaluation engine for benchmarking AI agent skills across any stack (Rails-first, but extensible).

---

## 🏷️ Identity
| Aspect | Value |
|--------|-------|
| Gem name | `ruby-skill-bench` |
| Module namespace | `SkillBench::` |
| CLI executable | `skill-bench` |
| Config file | `.skill-bench.yml` |
| Secrets | ENV vars only (12-factor) |

---

## 🏗️ Architecture
| Decision | Status |
|----------|--------|
| Merge namespaces (`lib/evaluator/` + `lib/agent_eval/` → `lib/skill_bench/`) | ✅ COMPLETE |
| Big-bang refactor | ✅ COMPLETE |
| Temp directory sandbox (no Docker) | ✅ COMPLETE |
| Hybrid scoring (deterministic v0.1.0 → LLM v0.2.0) | ✅ DECIDED |

---

## 📦 v0.1.0 Scope (MVP)

### ✅ Completed
- [x] Namespace merge to `SkillBench::`
- [x] 4 core CLI commands: `init`, `run`, `skill new`, `eval new`
- [x] 7 LLM providers (OpenAI, Anthropic, Gemini, Azure, Ollama, Groq, DeepSeek)
- [x] Gem renamed to `ruby-skill-bench`
- [x] CLI executable renamed to `bin/skill-bench`

### 🔄 In Progress
- [ ] Fix remaining test file references (~19 files with old `Evaluator::` references)
- [ ] Implement deterministic scoring in `ScoringService` (test pass rate, timing, error handling)
- [ ] Improve `persistence_service_test.rb` to 85%+ coverage
- [ ] Connect `criteria.json` to scoring logic
- [ ] Add `--force` flag to `init` command
- [ ] Add path validation in `RunnerService`

### ❌ Deferred
- [ ] `list` and `score` commands → v0.2.0
- [ ] LLM judge scoring → v0.2.0
- [ ] MCP Server → v1.1.0
- [ ] Web dashboard → v2.0.0

---

## 🔧 Implementation Phases

### Phase 1: Foundation (Big-Bang Refactor) - ✅ COMPLETE
1. [x] Rename `agent-eval.gemspec` → `ruby-skill-bench.gemspec`
2. [x] Merge `lib/agent_eval/` + `lib/evaluator/` → `lib/skill_bench/`
3. [x] Update all namespaces: `AgentEval::` → `SkillBench::`, `Evaluator::` → `SkillBench::`
4. [x] Rename `bin/evaluate` → `bin/skill-bench`
5. [x] Update gemspec executables
6. [x] Fix all broken requires/imports
7. [ ] Run full test suite, fix all breaks **(IN PROGRESS)**

### Phase 2: Coverage & Quality
8. [ ] Improve `persistence_service_test.rb` to 85%+ coverage (mix of unit + integration tests)
9. [ ] Implement deterministic scoring in `ScoringService` (test pass rate, timing, error handling)
10. [ ] Connect `criteria.json` to scoring logic
11. [ ] Add path validation in `RunnerService`
12. [ ] Add `--force` flag to `init` command
13. [ ] Run rubocop, reek, skunk — fix all offenses
14. [ ] Verify 85%+ coverage gate

### Phase 3: Polish & Release
15. [ ] Update README with new name (`ruby-skill-bench`)
16. [ ] Update all documentation references
17. [ ] Add CHANGELOG.md (initial release notes)
18. [ ] Build gem locally: `gem build ruby-skill-bench.gemspec`
19. [ ] Test gem installation: `gem install ./ruby-skill-bench-0.1.0.gem`
20. [ ] Run full eval cycle end-to-end
21. [ ] Tag release: `git tag v0.1.0`
22. [ ] Publish to RubyGems

---

## 📊 Quality Gates
| Metric | Target | Current |
|--------|--------|---------|
| Test coverage | 85%+ | ~47% (needs work) |
| Rubocop | 0 offenses | TBD |
| Reek | 0 warnings | TBD |
| Tests | 0 failures | TBD |
| SkunkScore avg | <20 | TBD |

---

## 📝 Known Technical Debt (Post-v0.1.0)
1. ~19 test files need namespace updates (`Evaluator::` → `SkillBench::`)
2. LLM judge implementation for nuanced scoring
3. `list` and `score` CLI commands
4. MCP Server integration (fix path issues)

---

## 🚀 Success Criteria for v0.1.0
- [ ] User can `gem install ruby-skill-bench`
- [ ] User can `skill-bench init --rails` to generate config
- [ ] User can `skill-bench skill new my-skill --mode rails`
- [ ] User can `skill-bench eval new my-eval --runtime rails`
- [ ] User can `skill-bench run my-eval --skill my-skill --provider openai`
- [ ] Eval produces deterministic score (0.0-1.0)
- [ ] CI workflow runs tests on PR
- [ ] All docs are accurate and up-to-date

---

## 📋 Session Notes
**Date:** 2026-05-07
**Completed:**
- Gem renamed to `ruby-skill-bench`
- All code merged into `lib/skill_bench/`
- Namespace changed from `Evaluator::`/`AgentEval::` to `SkillBench::`
- CLI executable renamed to `skill-bench`
- `skill_bench.rb` entry point created and working

**Remaining:**
- Fix ~19 test files with old references
- Implement scoring logic
- Improve test coverage to 85%+
- Run full test suite successfully

---

**READY FOR NEXT SESSION**
