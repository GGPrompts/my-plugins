---
name: debugging
description: "Systematic debugging framework with root cause investigation, tracing, defense-in-depth validation, and verification. Use when: 'bug', 'test failure', 'unexpected behavior', 'error', 'not working', 'broken', before proposing fixes, when encountering any technical issue"
user-invocable: true
---

# Systematic Debugging

## Core Principle

**NO FIXES WITHOUT ROOT CAUSE INVESTIGATION FIRST**

Random fixes waste time and create new bugs. Quick patches mask underlying issues.

## The Iron Law

```
If you haven't completed root cause investigation, you cannot propose fixes.
```

## When to Use

Use for ANY technical issue:
- Test failures
- Bugs in production  
- Unexpected behavior
- Performance problems
- Build failures
- Integration issues

**Use this ESPECIALLY when:**
- Under time pressure (emergencies make guessing tempting)
- "Just one quick fix" seems obvious
- You've already tried multiple fixes
- Previous fix didn't work
- You don't fully understand the issue

## Quick Reference: The Four Phases

| Phase | Key Activities | Success Criteria |
|-------|---------------|------------------|
| **1. Root Cause** | Read errors, reproduce, check changes, gather evidence | Understand WHAT and WHY |
| **2. Pattern** | Find working examples, compare | Identify differences |
| **3. Hypothesis** | Form theory, test minimally | Confirmed or new hypothesis |
| **4. Implementation** | Create test, fix, verify | Bug resolved, tests pass |

## Red Flags - STOP and Follow Process

If you notice yourself considering:
- "Quick fix for now, investigate later"
- "Just try changing X and see if it works"
- "Add multiple changes, run tests"
- "Skip the test, I'll manually verify"
- "It's probably X, let me fix that"
- "I don't fully understand but this might work"
- "Pattern says X but I'll adapt it differently"
- "Here are the main problems: [lists fixes without investigation]"
- Proposing solutions before tracing data flow
- **"One more fix attempt" (when already tried 2+)**
- **Each fix reveals new problem in different place**

**ALL of these mean: STOP. Return to Phase 1.**

**If 3+ fixes failed:** Question the architecture (not just symptoms)

## Topic Guides

### 📖 **@references/systematic.md** - Four-Phase Framework
- Complete systematic debugging process
- Phase 1: Root cause investigation
- Phase 2: Pattern analysis
- Phase 3: Hypothesis and testing
- Phase 4: Implementation
- Multi-component system diagnostics
- 3+ fix failure → architectural questioning
- Human partner signals you're doing it wrong
- Common rationalizations to avoid

### 🔍 **@references/root-cause.md** - Backward Tracing
- Trace bugs backward through call stack
- Finding original trigger vs fixing symptoms
- Adding stack trace instrumentation
- Finding which test causes pollution
- Real example: empty projectDir

### 🛡️ **@references/defense-in-depth.md** - Multi-Layer Validation
- Validate at EVERY layer data passes through
- Layer 1: Entry point validation
- Layer 2: Business logic validation
- Layer 3: Environment guards
- Layer 4: Debug instrumentation
- Making bugs structurally impossible

### ✅ **@references/verification.md** - Evidence Before Claims
- The Iron Law: No completion claims without fresh verification
- The Gate Function (5 steps before any claim)
- Common failures and red flags
- Regression test red-green cycle
- Why this matters (trust, quality, honesty)

## Common Patterns

### Multi-Component Diagnostic

```bash
# Layer 1: Workflow
echo "=== Secrets available in workflow: ==="
echo "VAR: ${VAR:+SET}${VAR:-UNSET}"

# Layer 2: Build script
echo "=== Env vars in build script: ==="
env | grep VAR || echo "VAR not in environment"

# Layer 3: Target script
echo "=== State at execution: ==="
./script.sh --verbose

# Reveals: Which layer fails
```

### Stack Trace Addition

```typescript
// Before problematic operation
async function operation(param: string) {
  const stack = new Error().stack;
  console.error('DEBUG operation:', {
    param,
    cwd: process.cwd(),
    env: process.env.NODE_ENV,
    stack,
  });
  
  await doRiskyThing(param);
}
```

### Defense-in-Depth Pattern

```typescript
// Layer 1: Entry validation
function createThing(path: string) {
  if (!path || path.trim() === '') {
    throw new Error('path cannot be empty');
  }
  
  // Layer 2: Business logic
  if (!existsSync(path)) {
    throw new Error(`path does not exist: ${path}`);
  }
  
  // Layer 3: Environment guard
  if (process.env.NODE_ENV === 'test') {
    if (!path.startsWith(tmpdir())) {
      throw new Error('Test operations must use temp dir');
    }
  }
  
  // Layer 4: Debug instrumentation
  logger.debug('Creating thing', { path, caller: new Error().stack });
  
  // Now safe to proceed
}
```

## Integration

This skill works with:
- **systematic-thinking** - Deep analysis for complex bugs
- **code-review** - Catch bugs before they ship
- **validate-plan** - Ensure fix approach is sound

## Real-World Impact

From debugging sessions:
- Systematic approach: 15-30 minutes to fix
- Random fixes approach: 2-3 hours of thrashing
- First-time fix rate: 95% vs 40%
- New bugs introduced: Near zero vs common

---

**The Bottom Line:**

1. **Find root cause BEFORE proposing fixes**
2. **Trace backward to original trigger**
3. **Validate at EVERY layer**
4. **Verify BEFORE claiming success**

This is non-negotiable.
