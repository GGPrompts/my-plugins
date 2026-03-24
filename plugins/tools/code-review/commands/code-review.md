---
description: Language-agnostic code review with dynamic agent planning
---

Review code using dynamically planned scanner agents that adapt to the project's language, size, and complexity.

## Usage

```bash
/code-review                          # Review uncommitted changes
/code-review --full                   # Review entire codebase
/code-review --files src/api tests/   # Review specific paths
/code-review <issue-id>              # Review changes for a beads issue
/code-review --quick                  # Fast mode: lint/build check only
```

## Architecture

```
DISCOVER → SCOPE → PLAN → SCAN (parallel) → AGGREGATE → FIX (if needed) → REPORT
```

- **Clean code:** N cheap Haiku scanners, done
- **Issues found:** N Haiku + 1 Opus fixer

## Process

Make a todo list before starting, then follow each phase.

### Phase 1: DISCOVER

Detect the project's languages, frameworks, and tooling. Run these inline (no agent needed):

```bash
# Detect build files
ls go.mod Cargo.toml package.json pyproject.toml requirements.txt Makefile CMakeLists.txt build.gradle pom.xml *.cabal stack.yaml mix.exs Gemfile composer.json 2>/dev/null

# Count files by language
find . -type f \( -name "*.go" -o -name "*.py" -o -name "*.ts" -o -name "*.tsx" -o -name "*.js" -o -name "*.jsx" -o -name "*.rs" -o -name "*.java" -o -name "*.rb" -o -name "*.cpp" -o -name "*.c" -o -name "*.cs" -o -name "*.ex" -o -name "*.exs" -o -name "*.hs" -o -name "*.php" \) -not -path "./.git/*" -not -path "*/node_modules/*" -not -path "*/vendor/*" 2>/dev/null | sed 's/.*\.//' | sort | uniq -c | sort -rn | head -10

# Detect available linters/build tools
which golangci-lint go ruff mypy pylint eslint tsc cargo clippy rustfmt mix rubocop phpstan 2>/dev/null

# Check for lint/build targets in Makefile
grep -E "^[a-zA-Z_-]+:" Makefile 2>/dev/null | head -20

# Find CLAUDE.md files
find . -name "CLAUDE.md" -not -path "./.git/*" 2>/dev/null
```

Build a mental model:
- **Primary language(s)** and file extensions
- **Frameworks** (check imports in build files)
- **Build command** (e.g., `go build ./...`, `cargo check`, `npm run build`)
- **Lint command** (e.g., `golangci-lint run`, `ruff check .`, `npm run lint`)
- **Test command** (e.g., `go test ./...`, `pytest`, `npm test`)
- **Comment syntax** (`//` for Go/JS/TS/Rust/Java/C, `#` for Python/Ruby/Shell)
- **Whether CLAUDE.md exists**

### Phase 2: SCOPE

Determine what to review based on invocation mode:

**No arguments (diff mode):**
```bash
git diff HEAD --stat
git diff HEAD
```
Count changed lines for sizing.

**`--full` (full codebase):**
```bash
# List source files (use discovered extensions)
find . -type f -name "*.go" -not -path "./.git/*" -not -path "*/vendor/*" | head -200
# Get total lines for sizing
find . -type f -name "*.go" -not -path "./.git/*" | xargs wc -l 2>/dev/null | tail -1
```
For large codebases (>5000 LOC), prioritize recently changed files:
```bash
git log --since="30 days" --name-only --pretty=format: | sort -u | head -100
```

**`--files <paths>`:**
```bash
find <paths> -type f -name "*.go" | head -100
```

**`<issue-id>`:**

Prefer MCP if available, fall back to CLI:
```
# MCP (preferred — cleaner output, no env var issues)
mcp__beads__show(issue_id="<issue-id>")

# CLI fallback
bd show <issue-id> --json
```
Then find the related commits and diff:
```bash
git log --oneline --all --grep="<issue-id>" | head -5
git diff <base>..<head>
```

Record: `SCOPE_TYPE` (diff/full/files/issue), `SCOPE_SIZE` (lines/files), `SCOPE_FILES` (list).

### Phase 3: PLAN

Based on discovery and scope, decide how many scanners and what each focuses on.

**Agent count guidelines:**

| Scope Size | Scanner Count |
|------------|---------------|
| Small (<100 lines or <10 files) | 2-3 |
| Medium (100-500 lines or 10-30 files) | 3-5 |
| Large (>500 lines or >30 files) | 5-8 |

**Always include:**
- Security scanner
- Error handling scanner

**Add based on context:**
- Git history context scanner (for diffs, not full reviews)
- Bug detection scanner (for medium+ scope)
- Architecture/duplication scanner (for large/full reviews)
- Per-language scanner if multiple significant languages exist
- CLAUDE.md compliance scan if CLAUDE.md exists

**For each scanner, craft a prompt using this template:**

```
FOCUS: [category] in [language] code
PROJECT: [language] [version if known] with [framework]
SCOPE: [one of: "Run git diff HEAD and review added/modified lines" | "Review these files: [list]" | "Review all [ext] files in [paths]"]
LOOK FOR:
- [pattern 1 with specific search strategy]
- [pattern 2]
- [pattern 3]
VERIFY: [build/lint command] 2>&1 | head -20
```

Use the **Language Pattern Library** below to populate LOOK FOR for each scanner.

### Phase 4: SCAN (parallel)

**CRITICAL:** Launch ALL scanner agents in a SINGLE message for parallel execution.

```
Task(subagent_type="code-review:scanner", model="haiku",
     prompt="FOCUS: Security in Go code\nPROJECT: ...\nSCOPE: ...\nLOOK FOR:\n- ...\nVERIFY: ...")

Task(subagent_type="code-review:scanner", model="haiku",
     prompt="FOCUS: Error handling in Go code\nPROJECT: ...\nSCOPE: ...\nLOOK FOR:\n- ...")

Task(subagent_type="code-review:claude-md-scan", model="haiku",
     prompt="SCOPE: diff\nReview uncommitted changes against CLAUDE.md rules.")
```

Each scanner returns JSON with `passed`, `flagged[]`, and `blockers[]`.

### Phase 5: AGGREGATE

1. Collect JSON results from all scanners
2. Merge all `flagged` and `blockers` arrays
3. **Deduplicate**: same file:line from multiple scanners → keep highest confidence, combine categories
4. **Filter**: remove findings with confidence < 80%
5. **Sort**: by confidence descending

### Phase 6: FIX (conditional)

**If no issues >= 80% confidence:** skip to Phase 7.

**If issues found:**

```
Task(subagent_type="code-review:fixer", model="opus",
     prompt="PROJECT CONTEXT:
     Language: [lang]
     Build: [build_cmd]
     Lint: [lint_cmd]
     Test: [test_cmd]
     Comment syntax: [// or #]

     AGGREGATED FINDINGS:
     [merged JSON from Phase 5]")
```

### Phase 7: REPORT

**No issues:**
```
--- Code Review Report ---
Project: [language] ([framework])
Scope: [description of what was reviewed]
Scanners: N ([list of focus areas])

PASSED — No issues found.
```

**Issues fixed:**
```
--- Code Review Report ---
Project: [language] ([framework])
Scope: [description]
Scanners: N ([list])

PASSED

Auto-fixed (N):
- [CATEGORY] Description in file:line (confidence%)

Flagged for review (N):
- [CATEGORY] Description in file:line (confidence%)

Build verification: [PASSED/FAILED/SKIPPED]
```

**Blockers remain:**
```
--- Code Review Report ---
...
FAILED

BLOCKERS (must fix):
- [CATEGORY] Description in file:line (confidence%)

Auto-fixed (N):
- ...

Fix blockers and run /code-review again.
```

### Quick Mode (`--quick`)

Skip all agents. Just run discovered lint/build tools:

```bash
# Run whatever was discovered in Phase 1, e.g.:
go vet ./... 2>&1 | head -30
golangci-lint run ./... 2>&1 | head -30
# or:
ruff check . 2>&1 | head -30
# or:
npx tsc --noEmit 2>&1 | head -30
```

Also check for exposed secrets:
```bash
grep -rn "password.*=.*['\"].\{8,\}\|api.key.*=.*['\"].\{8,\}\|secret.*=.*['\"].\{8,\}" --include="*" -l 2>/dev/null | grep -v node_modules | grep -v vendor | grep -v .git | head -10
```

If all pass: "Quick checks passed" and STOP.

---

## Language Pattern Library

Reference this when crafting scanner prompts. Pick patterns relevant to the detected language.

### Go
**Security:**
- SQL injection via `fmt.Sprintf` or string concatenation in queries (search: `Sprintf.*SELECT\|Sprintf.*INSERT\|Sprintf.*UPDATE\|Sprintf.*DELETE`)
- Command injection via `os/exec` with user input
- Hardcoded secrets, API keys, tokens
- Missing TLS verification (`InsecureSkipVerify: true`)

**Error Handling:**
- Ignored errors: `_ = someFunc()` or unchecked `err` after assignment
- Bare returns: `if err != nil { return }` without wrapping or logging
- Missing error context: `return err` instead of `return fmt.Errorf("context: %w", err)`
- Deferred function errors ignored: `defer f.Close()` without checking error
- `panic()` in library code (should return error)

**Bugs:**
- Nil pointer dereference without guard check
- Goroutine leaks (goroutine started without cancellation/context)
- Race conditions (shared state without mutex)
- Defer in loop (deferred calls won't run until function returns)
- Slice append gotcha (appending to a sub-slice may modify original)

**Verify:** `go build ./... && go vet ./...` or `golangci-lint run ./...`

### Python
**Security:**
- `eval()`, `exec()` with user input
- `pickle.loads()` / `yaml.load()` with untrusted data (use `yaml.safe_load`)
- SQL injection via f-strings or `.format()` in queries
- `os.system()` / `subprocess.call(shell=True)` with user input
- Hardcoded secrets

**Error Handling:**
- Bare `except:` or `except Exception:` with just `pass`
- Catching too broadly without re-raising
- Missing `finally` for resource cleanup
- Swallowed exceptions in async code

**Bugs:**
- Mutable default arguments (`def f(x=[])`)
- Late binding closures in loops
- `is` vs `==` for value comparison
- Missing `await` on coroutines
- Import cycle issues

**Verify:** `ruff check .` or `mypy .` or `python -m py_compile <file>`

### TypeScript / JavaScript
**Security:**
- `innerHTML` / `dangerouslySetInnerHTML` with user data
- `eval()`, `Function()` constructor
- SQL template strings without parameterization
- Hardcoded API keys, tokens

**Error Handling:**
- Empty catch blocks
- Unhandled promise rejections (missing `.catch()` or `try/catch` on `await`)
- Missing `await` on async functions (floating promises)

**Bugs:**
- `==` instead of `===` (type coercion)
- Null/undefined access without optional chaining
- State update race conditions in React (`setState(count + 1)` vs `setState(c => c + 1)`)
- Event listener leaks (missing cleanup in `useEffect`)
- Type assertions that hide errors (`as any`, `as unknown as T`)

**Verify:** `npx tsc --noEmit` or `npm run lint` or `npx eslint .`

### Rust
**Security:**
- `unsafe` blocks — review for soundness
- Unchecked FFI calls
- Path traversal in file operations

**Error Handling:**
- `.unwrap()` on `Result`/`Option` (use `?` or proper matching)
- `panic!()` in library code
- Ignoring `Result` return values

**Bugs:**
- Use-after-move
- Deadlocks from lock ordering
- Integer overflow in release mode (wraps silently)
- Unbounded recursion

**Verify:** `cargo check` or `cargo clippy`

### General (any language)
**Git Context** (for diff reviews):
- Was similar code recently removed? (check `git log -S "pattern"`)
- Does this modify a recent bug fix? (check `git log --grep="fix" -- <file>`)
- Are there TODO/FIXME comments on modified lines?

**Architecture** (for full/large reviews):
- Functions longer than ~100 lines
- Duplicated code blocks across files
- Circular dependencies between packages/modules

## Agents

| Agent | Purpose | Model |
|-------|---------|-------|
| scanner | Generic scanner, invoked N times with different prompts | Haiku |
| claude-md-scan | CLAUDE.md compliance (if CLAUDE.md exists) | Haiku |
| fixer | Apply fixes for >= 90% confidence issues | Opus |

## Confidence Scoring

| Score | Action |
|-------|--------|
| 0-79 | Skip |
| 80-89 | Flag + TODO comment |
| 90-100 | Auto-fix |

## Notes

- Make a todo list before starting
- Use Task tool to spawn agents, not Bash
- Launch ALL scanner agents in ONE message (parallel execution)
- Opus fixer only runs when issues are found (cost optimization)
- Adapt scanner count and focus areas to the project — the guidelines above are not rigid rules
- For multi-language projects, create at least one scanner per significant language
