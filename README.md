# rralph

A self-improving task orchestrator for AI-assisted development. Based on Ralph Wiggum concept.

## Overview

`rralph` automates an iterative, AI-assisted development workflow. It reads your project's plan, learnings, and todo list, then orchestrates AI tool invocations to complete tasks one by one — learning, testing, and committing along the way.

## Installation

```
gem install rralph
```

Ralph by default uses `qwen-code` as the AI agent. You can override this with the `--ai-command` flag.

## Usage

### Prerequisites

Before running `rralph`, ensure you have:

1. A Git repository initialized
2. Three Markdown files in your working directory:
   - `plan.md` — Your high-level project plan
   - `learnings.md` — Accumulated insights (can start empty)
   - `todo.md` — Task list with checkboxes (one task per line, can be empty first, rralph will generate the tasks)

Example `plan.md`:

```markdown
Plan: Bash script that prints "IS EVEN" or "IS ODD" based on input.

Input: One integer as command-line argument.  
Output: "IS EVEN" if divisible by 2, "IS ODD" otherwise.  
Error: If no argument or non-integer, print error and exit 1.

Logic: Use % to check remainder. Validate input with regex: ^-?[0-9]+$.

File: odd_even.sh  
Requirements:

- Need to be in bash
- Validate input
- Use conditional with (( ))
- No external tools

Test: 0→EVEN, 7→ODD, -4→EVEN, abc→error, no arg→error
```

### Basic Usage

Run `rralph` with default settings:

```bash
rralph
```

Or with options:

```bash
rralph --max-failures 2 --watch
```

### Command-Line Options

```
rralph run [OPTIONS]

Options:
  -m, --max-failures N       Maximum allowed failures before stopping (default: 3)
  -a, --ai-command "CMD"     AI command to invoke (default: "qwen-code -y -s")
  -w, --watch                Run in continuous loop until completion or max failures
  -p, --plan-path PATH       Path to plan.md file (default: "plan.md")
  -l, --learnings-path PATH  Path to learnings.md file (default: "learnings.md")
  -t, --todo-path PATH       Path to todo.md file (default: "todo.md")
  -h, --help                 Show help message
```

### Examples

Run a single cycle:

```bash
rralph
```

Run continuously until all tasks are done or max failures reached:

```bash
rralph --watch --max-failures 5
```

Use a custom AI command:

```bash
rralph --ai-command "claude --prompt"
```

View progress statistics:

```bash
$> rralph stats
Tasks: 5/6 done
Pending: 1
Learnings: 6 lines
```

## How It Works

1. **Read** — `rralph` reads `plan.md`, `learnings.md`, and `todo.md`
2. **Prompt** — Builds a prompt with file contents and sends to LLM
3. **Parse** — Analyzes AI response for:
   - `FAILURE` keyword (case-insensitive, whole word)
   - New learnings to extract
4. **Update** — On success:
   - Marks current task as complete in `todo.md`
   - Appends new learnings to `learnings.md`
   - Commits all changes to Git
5. **Repeat** — In `--watch` mode, continues until done or max failures

### Failure Handling

- Each `FAILURE` response increments a counter
- Non-failure responses reset the counter to 0
- When max failures reached, `rralph` exits with error:
- ```
  Max failures reached (N). Stopping to avoid infinite loops. Review learnings.md and todo.md.
  ```

### Logging

Human-readable logs are output to stderr:

```
✅ [Cycle 4] Task completed. 0 failures. Git commit: abc123
❌ [Cycle 5] FAILURE detected. Failures: 2/3
```

In `--watch` mode, AI responses are saved to `logs/` for audit trail.

## License

Available as open source under the terms of the [MIT License](https://opensource.org/licenses/MIT).
