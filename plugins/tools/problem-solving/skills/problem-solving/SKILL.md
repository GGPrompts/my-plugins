---
name: problem-solving
description: "Problem-solving frameworks for breakthrough thinking - collision zones, simplification cascades, meta-patterns, scale testing, inversion, and dispatch guide. Use when: 'stuck', 'can't find solution', 'too complex', 'same problem everywhere', 'will this scale?', 'need innovation', 'which technique should I use?'"
user-invocable: true
---

# Problem-Solving Frameworks

Systematic techniques for breaking through complex problems, finding simplifying insights, and matching the right approach to your specific type of stuck.

## When to Use

Each framework targets a different type of "stuck":

| Symptom | Use This |
|---------|----------|
| Same thing implemented 5+ ways, complexity spiraling | **Simplification Cascades** |
| Can't find fitting approach, need breakthrough | **Collision Zone Thinking** |
| Same pattern in 3+ domains, reinventing wheels | **Meta-Pattern Recognition** |
| Will this scale? Edge cases unclear | **Scale Game** |
| Solution feels forced, "must be done this way" | **Inversion Exercise** |
| Unsure which technique to use | **When Stuck Dispatch** |

## Quick Reference

### 🎯 **@references/when-stuck.md** - Technique Dispatch
Decision tree to quickly identify which problem-solving technique to use based on your specific stuck-symptom.

### 🎨 **@references/collision-zones.md** - Force Unrelated Concepts Together
"What if we treated X like Y?" - Deliberate metaphor-mixing for breakthrough innovation.

**Examples:**
- Treat code like DNA → Mutation testing, evolutionary algorithms
- Treat architecture like Lego → Composable microservices
- Treat data like water → Streaming, data lakes
- Treat requests like postal mail → Message queues, async processing

### 🔄 **@references/simplification.md** - Find Unifying Insights
"If this is true, we don't need X, Y, or Z" - One insight that eliminates multiple components.

**Look for:**
- Same thing implemented 5+ ways
- Growing special case list
- Excessive if/else branching
- Multiple config variations

### 🔍 **@references/meta-patterns.md** - Spot Universal Principles
When the same pattern appears in 3+ domains, extract the universal principle.

**Examples:**
- Caching (CPU, DB, HTTP, DNS, LLM prompts, CDN)
- Layering (network stack, storage, architecture)
- Queuing (message, task, request queues)
- Pooling (connections, threads, objects, resources)

### ⚖️ **@references/scale-game.md** - Test at Extremes
1000x bigger/smaller, instant/year-long - extremes expose fundamental truths.

**Test dimensions:**
- Volume: 1 item vs 1 billion items
- Speed: Instant vs 1 year
- Users: 1 vs 1 billion concurrent
- Duration: Milliseconds vs years
- Failure rate: Never vs always fails

### 🔀 **@references/inversion.md** - Flip Assumptions
"What if the opposite were true?" - Reveals hidden constraints and alternatives.

**Examples:**
- Cache to reduce latency → Add latency to enable caching (debouncing)
- Pull data when needed → Push data before needed (prefetching)
- Handle errors when occur → Make errors impossible (type systems)
- Build features wanted → Remove features not needed (simplicity)

## Common Patterns

### Stuck on Complexity

```
1. List all similar implementations
2. Extract common pattern
3. Create general case
4. Replace all with unified implementation
5. Result: 5 components → 1 component
```

See @references/simplification.md

### Need Innovation

```
1. Pick two unrelated concepts (different domains)
2. Force combination: "What if [A] like [B]?"
3. Explore emergent properties
4. Test feasibility
5. Result: Novel approach
```

See @references/collision-zones.md

### Validate Architecture

```
1. Pick scale dimension (volume, speed, users, etc.)
2. Test minimum: 1000x smaller/faster
3. Test maximum: 1000x bigger/slower
4. Identify what breaks
5. Result: Fundamental limits exposed
```

See @references/scale-game.md

## Decision Tree

**Start here when stuck:**

```
Are you stuck on:

1. COMPLEXITY (same thing 5+ ways, special cases)
   → Use Simplification Cascades
   
2. INNOVATION (no fitting approach, need breakthrough)
   → Use Collision Zone Thinking
   
3. REPETITION (same pattern in 3+ places)
   → Use Meta-Pattern Recognition
   
4. SCALE (will this work in production?)
   → Use Scale Game
   
5. ASSUMPTIONS (feels forced, "must be this way")
   → Use Inversion Exercise
   
6. UNCLEAR (which technique to use?)
   → Read @references/when-stuck.md for detailed dispatch
```

## Key Principles

1. **Match technique to problem type** - Different stuck needs different approach
2. **Test at extremes** - Normal scales hide fundamental truths
3. **Extract universal patterns** - If it appears 3+ times, it's a principle
4. **Simplify aggressively** - One insight can eliminate 10 components
5. **Question assumptions** - The opposite might reveal the truth
6. **Force collisions** - Unrelated concepts spark innovation

## Real-World Examples

### Simplification Cascade
**Before:** 5 different authentication flows (OAuth, API key, JWT, session, basic)
**Insight:** "Everything is token validation"
**After:** 1 unified token validator + adapters

### Collision Zone
**Problem:** Slow data pipeline
**Collision:** "What if we treated data like streaming video?"
**Result:** Adaptive bitrate-style compression based on consumer capacity

### Meta-Pattern
**Observed:** Retries in HTTP, DB, queue, file system
**Abstracted:** "Exponential backoff with jitter"
**Applied:** Unified retry policy library

### Scale Game
**Question:** Will this work at 1M users?
**Test:** Simulate 1 user → works. 1B users → timeout.
**Discovery:** N² algorithm hidden in "simple" lookup
**Fix:** Add index, now O(log n)

### Inversion
**Assumption:** "Must validate input when received"
**Inversion:** "What if we never accepted invalid input?"
**Result:** Type system + schemas prevent invalid data at compile time

## Integration

Works with:
- **debugging** - Use these when systematic debugging doesn't reveal root cause
- **sequential-thinking** - Apply these techniques within thinking branches
- **validate-plan** - Use scale-game and inversion to stress-test plans

---

**Quick Start:**

1. Read @references/when-stuck.md for dispatch logic
2. Pick the technique matching your stuck-type
3. Follow that technique's specific process
4. If still stuck, try combining techniques

**Remember:** Different problems need different tools. Match the technique to the symptom.
