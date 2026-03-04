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

After running `rralph start` you will get a `todo.md` generated for you like:

```
# Todo List

- [ ] Create `odd_even.sh` file with bash shebang
- [ ] Add input validation to check if argument is provided
- [ ] Add regex validation for integer input (`^-?[0-9]+$`)
- [ ] Implement even/odd check using `(( ))` arithmetic and `%` operator
- [ ] Print "IS EVEN" or "IS ODD" based on result
- [ ] Add error handling with exit code 1 for invalid inputs
- [ ] Make script executable with `chmod +x`
- [ ] Test with input `0` (expect "IS EVEN")
- [ ] Test with input `7` (expect "IS ODD")
- [ ] Test with input `-4` (expect "IS EVEN")
- [ ] Test with input `abc` (expect error, exit 1)
- [ ] Test with no argument (expect error, exit 1)
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
➜  rralph help      
Commands:
  rralph help [COMMAND]  # Describe available commands or one specific command
  rralph start           # Run the rralph orchestrator
  rralph stats           # Show progress statistics
  rralph tree            # Print a tree of all available commands
  rralph version         # Show rralph version

➜  rralph help start
Usage:
  rralph start

Options:
  -m, [--max-failures=N]                       # Maximum allowed failures before stopping
                                               # Default: 3
  -a, [--ai-command=AI_COMMAND]                # AI command to invoke
                                               # Default: qwen-code -y -s
  -w, [--watch], [--no-watch], [--skip-watch]  # Run in continuous loop until completion or max failures
                                               # Default: false
  -p, [--plan-path=PLAN_PATH]                  # Path to plan.md file
                                               # Default: plan.md
  -l, [--learnings-path=LEARNINGS_PATH]        # Path to learnings.md file
                                               # Default: learnings.md
  -t, [--todo-path=TODO_PATH]                  # Path to todo.md file
                                               # Default: todo.md
  -s, [--skip-commit], [--no-skip-commit]      # Skip git commits between tasks
                                               # Default: false
  -v, [--verbose], [--no-verbose]              # Enable verbose logging with AI thinking and real-time output
                                               # Default: false
```

### Examples

Run a single cycle:

```bash
rralph
```

Run continuously until all tasks are done or max failures reached:

```bash
rralph start --watch --max-failures 5
```

Use a custom AI command:

```bash
rralph start --ai-command "claude --prompt"
```

Skip git commits between tasks (files are updated but not committed):

```bash
rralph start --skip-commit
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
   - `TASK_FAILURE` keyword (case-sensitive, whole word)
   - New learnings to extract
4. **Update** — On success:
   - Marks current task as complete in `todo.md`
   - Appends new learnings to `learnings.md`
   - Commits all changes to Git
5. **Repeat** — In `--watch` mode, continues until done or max failures

### Failure Handling

- Each `TASK_FAILURE` response increments a counter
- Non-failure responses reset the counter to 0
- When max failures reached, `rralph` exits with error:
- ```
  Max failures reached (N). Stopping to avoid infinite loops. Review learnings.md and todo.md.
  ```

### Logging

By default, `rralph` outputs concise progress logs to stderr:

```
Starting rralph with max_failures=3, ai_command='qwen-code -y -s'
Cycle 1: Processing task: Create odd_even.sh file with bash shebang
Executing AI command...
Completed in 2341ms (13407 tokens)
[Cycle 1] Task completed. 0 failures. Git commit: abc123
   Log saved: logs/cycle_1_20260302_145738.md
```

Use `--verbose` mode for detailed real-time logging including AI thinking:

```bash
rralph start --verbose
```

Verbose output shows:
- Thinking: AI's thought process as it thinks
- Real-time text output from the AI
- Completion metrics (duration, token usage)

Example verbose output:

```
Executing AI command...
Thinking: The user wants me to create a bash script for checking even/odd numbers
Thinking: I need to start with the basic file structure and shebang
   I'll create the odd_even.sh file with a proper bash shebang.
Completed in 1847ms (8234 tokens)
```

In `--watch` mode, full AI responses are saved to `logs/` for audit trail.

## License

Available as open source under the terms of the [MIT License](https://opensource.org/licenses/MIT).
