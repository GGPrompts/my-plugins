# Anthropic Claude 4.x Prompting Best Practices

> Source: https://platform.claude.com/docs/en/build-with-claude/prompt-engineering/claude-4-best-practices

This guide provides specific prompt engineering techniques for Claude 4.x models (Sonnet 4.5, Haiku 4.5, and Opus 4.5). These models have been trained for more precise instruction following than previous generations.

---

## General Principles

### Be Explicit with Your Instructions

Claude 4.x models respond well to clear, explicit instructions. Being specific about your desired output can help enhance results. Customers who desire the "above and beyond" behavior from previous Claude models might need to more explicitly request these behaviors with newer models.

**Less effective:**
```text
Create an analytics dashboard
```

**More effective:**
```text
Create an analytics dashboard. Include as many relevant features and interactions as possible. Go beyond the basics to create a fully-featured implementation.
```

### Add Context to Improve Performance

Providing context or motivation behind your instructions, such as explaining to Claude why such behavior is important, can help Claude 4.x models better understand your goals and deliver more targeted responses.

**Less effective:**
```text
NEVER use ellipses
```

**More effective:**
```text
Your response will be read aloud by a text-to-speech engine, so never use ellipses since the text-to-speech engine will not know how to pronounce them.
```

Claude is smart enough to generalize from the explanation.

### Be Vigilant with Examples & Details

Claude 4.x models pay close attention to details and examples as part of their precise instruction following capabilities. Ensure that your examples align with the behaviors you want to encourage and minimize behaviors you want to avoid.

---

## Long-Horizon Reasoning and State Tracking

Claude 4.5 models excel at long-horizon reasoning tasks with exceptional state tracking capabilities. It maintains orientation across extended sessions by focusing on incremental progress—making steady advances on a few things at a time rather than attempting everything at once.

### Context Awareness and Multi-Window Workflows

Claude 4.5 models feature context awareness, enabling the model to track its remaining context window (i.e. "token budget") throughout a conversation.

**Managing context limits:**

```text
Your context window will be automatically compacted as it approaches its limit, allowing you to continue working indefinitely from where you left off. Therefore, do not stop tasks early due to token budget concerns. As you approach your token budget limit, save your current progress and state to memory before the context window refreshes. Always be as persistent and autonomous as possible and complete tasks fully, even if the end of your budget is approaching. Never artificially stop any task early regardless of the context remaining.
```

### Multi-Context Window Workflows

For tasks spanning multiple context windows:

1. **Use a different prompt for the very first context window**: Use the first context window to set up a framework (write tests, create setup scripts), then use future context windows to iterate on a todo-list.

2. **Have the model write tests in a structured format**: Ask Claude to create tests before starting work and keep track of them in a structured format (e.g., `tests.json`). Remind Claude: "It is unacceptable to remove or edit tests as this could lead to missing or buggy functionality."

3. **Set up quality of life tools**: Encourage Claude to create setup scripts (e.g., `init.sh`) to gracefully start servers, run test suites, and linters.

4. **Starting fresh vs compacting**: When a context window is cleared, consider starting with a brand new context window rather than using compaction. Be prescriptive:
   - "Call pwd; you can only read and write files in this directory."
   - "Review progress.txt, tests.json, and the git logs."
   - "Manually run through a fundamental integration test before moving on."

5. **Provide verification tools**: Tools like Playwright MCP server or computer use capabilities for testing UIs.

6. **Encourage complete usage of context**:
```text
This is a very long task, so it may be beneficial to plan out your work clearly. It's encouraged to spend your entire output context working on the task - just make sure you don't run out of context with significant uncommitted work.
```

### State Management Best Practices

- **Use structured formats for state data**: JSON for test results, task status
- **Use unstructured text for progress notes**: Freeform progress notes for general tracking
- **Use git for state tracking**: Git provides a log and checkpoints
- **Emphasize incremental progress**: Explicitly ask Claude to track progress

**Example state files:**

```json
// Structured state file (tests.json)
{
  "tests": [
    {"id": 1, "name": "authentication_flow", "status": "passing"},
    {"id": 2, "name": "user_management", "status": "failing"},
    {"id": 3, "name": "api_endpoints", "status": "not_started"}
  ],
  "total": 200,
  "passing": 150,
  "failing": 25,
  "not_started": 25
}
```

```text
// Progress notes (progress.txt)
Session 3 progress:
- Fixed authentication token validation
- Updated user model to handle edge cases
- Next: investigate user_management test failures (test #2)
- Note: Do not remove tests as this could lead to missing functionality
```

---

## Communication Style

Claude 4.5 models have a more concise and natural communication style:

- **More direct and grounded**: Fact-based progress reports rather than self-celebratory updates
- **More conversational**: Slightly more fluent and colloquial, less machine-like
- **Less verbose**: May skip detailed summaries for efficiency unless prompted

### Balance Verbosity

If you want Claude to provide updates as it works:

```text
After completing a task that involves tool use, provide a quick summary of the work you've done.
```

---

## Tool Usage Patterns

Claude 4.5 models are trained for precise instruction following and benefits from explicit direction. If you say "can you suggest some changes," it will sometimes provide suggestions rather than implementing them.

**Less effective (Claude will only suggest):**
```text
Can you suggest some changes to improve this function?
```

**More effective (Claude will make the changes):**
```text
Change this function to improve its performance.
```

### Proactive Action Prompt

```xml
<default_to_action>
By default, implement changes rather than only suggesting them. If the user's intent is unclear, infer the most useful likely action and proceed, using tools to discover any missing details instead of guessing. Try to infer the user's intent about whether a tool call (e.g., file edit or read) is intended or not, and act accordingly.
</default_to_action>
```

### Conservative Action Prompt

```xml
<do_not_act_before_instructions>
Do not jump into implementation or change files unless clearly instructed to make changes. When the user's intent is ambiguous, default to providing information, doing research, and providing recommendations rather than taking action. Only proceed with edits, modifications, or implementations when the user explicitly requests them.
</do_not_act_before_instructions>
```

### Tool Triggering Calibration

Claude Opus 4.5 is more responsive to the system prompt than previous models. If your prompts were designed to reduce undertriggering on tools or skills, Claude Opus 4.5 may now overtrigger.

**Fix:** Dial back aggressive language. Where you might have said "CRITICAL: You MUST use this tool when...", use more normal prompting like "Use this tool when...".

---

## Control the Format of Responses

### 1. Tell Claude What to Do (Not What Not to Do)

- Instead of: "Do not use markdown in your response"
- Try: "Your response should be composed of smoothly flowing prose paragraphs."

### 2. Use XML Format Indicators

```text
Write the prose sections of your response in <smoothly_flowing_prose_paragraphs> tags.
```

### 3. Match Prompt Style to Desired Output

The formatting style in your prompt may influence Claude's response style. Removing markdown from your prompt can reduce markdown in the output.

### 4. Detailed Formatting Prompt

```xml
<avoid_excessive_markdown_and_bullet_points>
When writing reports, documents, technical explanations, analyses, or any long-form content, write in clear, flowing prose using complete paragraphs and sentences. Use standard paragraph breaks for organization and reserve markdown primarily for `inline code`, code blocks, and simple headings.

DO NOT use ordered lists (1. ...) or unordered lists (*) unless:
a) you're presenting truly discrete items where a list format is the best option, or
b) the user explicitly requests a list or ranking

Instead of listing items with bullets or numbers, incorporate them naturally into sentences. Your goal is readable, flowing text that guides the reader naturally through ideas rather than fragmenting information into isolated points.
</avoid_excessive_markdown_and_bullet_points>
```

---

## Research and Information Gathering

Claude 4.5 models demonstrate exceptional agentic search capabilities.

**For complex research tasks:**

```text
Search for this information in a structured way. As you gather data, develop several competing hypotheses. Track your confidence levels in your progress notes to improve calibration. Regularly self-critique your approach and plan. Update a hypothesis tree or research notes file to persist information and provide transparency. Break down this complex research task systematically.
```

---

## Subagent Orchestration

Claude 4.5 models can recognize when tasks benefit from delegating to specialized subagents and do so proactively.

**For conservative subagent usage:**

```text
Only delegate to subagents when the task clearly benefits from a separate agent with a new context window.
```

---

## Thinking Sensitivity

When extended thinking is disabled, Claude Opus 4.5 is particularly sensitive to the word "think" and its variants. Replace with:
- "consider" instead of "think about"
- "believe" instead of "think"
- "evaluate" instead of "think through"

### Leverage Thinking Capabilities

```text
After receiving tool results, carefully reflect on their quality and determine optimal next steps before proceeding. Use your thinking to plan and iterate based on this new information, and then take the best next action.
```

---

## Parallel Tool Calling

Claude 4.x models excel at parallel tool execution. Minor prompting can boost parallel tool use to ~100%:

```xml
<use_parallel_tool_calls>
If you intend to call multiple tools and there are no dependencies between the tool calls, make all of the independent tool calls in parallel. Prioritize calling tools simultaneously whenever the actions can be done in parallel rather than sequentially. For example, when reading 3 files, run 3 tool calls in parallel to read all 3 files into context at the same time. Maximize use of parallel tool calls where possible to increase speed and efficiency. However, if some tool calls depend on previous calls to inform dependent values like the parameters, do NOT call these tools in parallel and instead call them sequentially. Never use placeholders or guess missing parameters in tool calls.
</use_parallel_tool_calls>
```

**To reduce parallel execution:**
```text
Execute operations sequentially with brief pauses between each step to ensure stability.
```

---

## Reduce File Creation in Agentic Coding

Claude 4.x may create temporary files for testing. To minimize:

```text
If you create any temporary new files, scripts, or helper files for iteration, clean up these files by removing them at the end of the task.
```

---

## Overeagerness and Over-Engineering

Claude Opus 4.5 tends to overengineer. Add explicit prompting:

```xml
<avoid_over_engineering>
Avoid over-engineering. Only make changes that are directly requested or clearly necessary. Keep solutions simple and focused.

Don't add features, refactor code, or make "improvements" beyond what was asked. A bug fix doesn't need surrounding code cleaned up. A simple feature doesn't need extra configurability.

Don't add error handling, fallbacks, or validation for scenarios that can't happen. Trust internal code and framework guarantees. Only validate at system boundaries (user input, external APIs). Don't use backwards-compatibility shims when you can just change the code.

Don't create helpers, utilities, or abstractions for one-time operations. Don't design for hypothetical future requirements. The right amount of complexity is the minimum needed for the current task. Reuse existing abstractions where possible and follow the DRY principle.
</avoid_over_engineering>
```

---

## Frontend Design

Claude 4.x can default to generic patterns creating "AI slop" aesthetic. For distinctive frontends:

```xml
<frontend_aesthetics>
You tend to converge toward generic, "on distribution" outputs. In frontend design, this creates what users call the "AI slop" aesthetic. Avoid this: make creative, distinctive frontends that surprise and delight.

Focus on:
- Typography: Choose fonts that are beautiful, unique, and interesting. Avoid generic fonts like Arial and Inter; opt instead for distinctive choices that elevate the frontend's aesthetics.
- Color & Theme: Commit to a cohesive aesthetic. Use CSS variables for consistency. Dominant colors with sharp accents outperform timid, evenly-distributed palettes. Draw from IDE themes and cultural aesthetics for inspiration.
- Motion: Use animations for effects and micro-interactions. Prioritize CSS-only solutions for HTML. Use Motion library for React when available. Focus on high-impact moments: one well-orchestrated page load with staggered reveals creates more delight than scattered micro-interactions.
- Backgrounds: Create atmosphere and depth rather than defaulting to solid colors. Layer CSS gradients, use geometric patterns, or add contextual effects.

Avoid generic AI-generated aesthetics:
- Overused font families (Inter, Roboto, Arial, system fonts)
- Clichéd color schemes (particularly purple gradients on white backgrounds)
- Predictable layouts and component patterns
- Cookie-cutter design that lacks context-specific character

Interpret creatively and make unexpected choices that feel genuinely designed for the context. Vary between light and dark themes, different fonts, different aesthetics.
</frontend_aesthetics>
```

---

## Avoid Hard-Coding and Test-Focused Solutions

```text
Please write a high-quality, general-purpose solution using the standard tools available. Do not create helper scripts or workarounds to accomplish the task more efficiently. Implement a solution that works correctly for all valid inputs, not just the test cases. Do not hard-code values or create solutions that only work for specific test inputs. Instead, implement the actual logic that solves the problem generally.

Focus on understanding the problem requirements and implementing the correct algorithm. Tests are there to verify correctness, not to define the solution. Provide a principled implementation that follows best practices and software design principles.

If the task is unreasonable or infeasible, or if any of the tests are incorrect, please inform me rather than working around them.
```

---

## Encouraging Code Exploration

If Claude proposes solutions without reading code:

```text
ALWAYS read and understand relevant files before proposing code edits. Do not speculate about code you have not inspected. If the user references a specific file/path, you MUST open and inspect it before explaining or proposing fixes. Be rigorous and persistent in searching code for key facts. Thoroughly review the style, conventions, and abstractions of the codebase before implementing new features or abstractions.
```

---

## Minimizing Hallucinations

```xml
<investigate_before_answering>
Never speculate about code you have not opened. If the user references a specific file, you MUST read the file before answering. Make sure to investigate and read relevant files BEFORE answering questions about the codebase. Never make any claims about code before investigating unless you are certain of the correct answer - give grounded and hallucination-free answers.
</investigate_before_answering>
```

---

## Model Self-Knowledge

```text
The assistant is Claude, created by Anthropic. The current model is Claude Sonnet 4.5.
```

For API model strings:
```text
When an LLM is needed, please default to Claude Sonnet 4.5 unless the user requests otherwise. The exact model string for Claude Sonnet 4.5 is claude-sonnet-4-5-20250929.
```

---

## Migration Considerations

When migrating to Claude 4.5:

1. **Be specific about desired behavior**: Describe exactly what you'd like to see in the output.

2. **Frame instructions with modifiers**: Add modifiers that encourage quality and detail. Instead of "Create an analytics dashboard", use "Create an analytics dashboard. Include as many relevant features and interactions as possible. Go beyond the basics to create a fully-featured implementation."

3. **Request specific features explicitly**: Animations and interactive elements should be requested explicitly when desired.

---

## Model String Reference

| Model | String |
|-------|--------|
| Claude Opus 4.5 | `claude-opus-4-5-20251101` |
| Claude Sonnet 4.5 | `claude-sonnet-4-5-20250929` |
| Claude Haiku 4.5 | `claude-haiku-4-5-20250929` |
