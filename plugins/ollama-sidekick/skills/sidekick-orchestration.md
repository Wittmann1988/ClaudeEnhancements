---
name: sidekick-orchestration
description: Always-active orchestration rules for the Ollama Nemotron sidekick agent
alwaysActive: true
---

# Ollama Sidekick Orchestration

You have a sidekick agent powered by **Nemotron-3-Nano 30B** (a multi-agent system with 126 specialized agents) available via MCP tools. This sidekick is ALWAYS available and MUST be used according to these rules.

## Available MCP Tools

| Tool | Purpose |
|------|---------|
| `sidekick_research` | Search for existing repos/libs BEFORE writing code |
| `sidekick_review` | Review code after implementation |
| `sidekick_analyze` | Get second opinion on task approach |
| `sidekick_ask` | Free-form query to Nemotron |
| `sidekick_search_repos` | Search GitHub for existing implementations |

## MANDATORY Rules

### Rule 1: Research First — NEVER Skip
Before implementing ANY feature, component, or significant code block:
1. Call `sidekick_research` with the topic
2. Call `sidekick_search_repos` to find existing implementations
3. Review results and decide: use existing code or build from scratch
4. If existing code found → adapt it. Do NOT reinvent.

**This is the most important rule.** The user's #1 frustration is code being written from scratch when existing solutions exist.

### Rule 2: Parallel Research
When starting implementation on a task:
- Launch `sidekick_research` in parallel (via Agent tool) while you begin work
- Use the research results to course-correct as they come in
- This maximizes speed — you don't wait idle for research

### Rule 3: Auto-Review After Implementation
After writing any significant code block (>20 lines or critical logic):
- Call `sidekick_review` with the code
- Address any security or quality issues found
- Report review results to the user

### Rule 4: Second Opinion on Architecture
When facing architectural decisions or multiple valid approaches:
- Call `sidekick_analyze` before committing to an approach
- Present both your reasoning and the sidekick's analysis
- Let the user decide if there's disagreement

### Rule 5: Use for Delegation
For tasks that don't require Claude's full capabilities:
- Delegate research, boilerplate analysis, and pattern matching to the sidekick
- Use the sidekick for gathering context while you focus on implementation
- The sidekick's 126-agent system excels at decomposed subtasks

## When NOT to Use the Sidekick

- Simple file edits (typos, config changes)
- Tasks where the user explicitly says "just do it"
- When the sidekick has already been consulted for the same topic in this session
- Git operations, file management, and other mechanical tasks

## Integration with Other Skills

- **brainstorming** → Use `sidekick_analyze` during approach evaluation
- **test-driven-development** → Use `sidekick_review` on test code
- **code-review** → Combine with `sidekick_review` for dual perspective
- **dispatching-parallel-agents** → Delegate sidekick calls to parallel agents
- **systematic-debugging** → Use `sidekick_ask` for debugging hypotheses
