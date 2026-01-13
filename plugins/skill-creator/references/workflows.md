# Workflow Patterns

Patterns for structuring multi-step processes in skills.

## Sequential Workflows

Break complex tasks into ordered steps. Provide overview early.

### Example: PDF Form Filling

```markdown
## Workflow

1. **Analyze** - Read the PDF form structure
2. **Map** - Create field mapping from source data
3. **Validate** - Verify all required fields have values
4. **Fill** - Write values to PDF fields
5. **Verify** - Check output matches expectations
```

### When to Use

- Steps must happen in order
- Each step depends on previous output
- Process is well-defined with little variation

## Conditional Workflows

Incorporate branching logic with decision points.

### Example: Content Modification

```markdown
## Workflow

1. **Determine modification type:**
   - **Creating new content?** → Follow "Creation workflow"
   - **Editing existing content?** → Follow "Editing workflow"

### Creation Workflow
1. Gather requirements
2. Draft outline
3. Write content
4. Review and refine

### Editing Workflow
1. Understand current state
2. Identify changes needed
3. Apply modifications
4. Verify changes preserved intent
```

### When to Use

- Multiple valid paths exist
- Context determines approach
- Some steps only apply conditionally

## Degrees of Freedom

Match instruction specificity to task fragility:

| Freedom Level | Format | Use When |
|---------------|--------|----------|
| **High** | Text-based instructions | Flexible approaches acceptable |
| **Medium** | Pseudocode with parameters | Some variation OK, structure matters |
| **Low** | Specific scripts | Reliability critical, minimal variation |

### High Freedom Example

```markdown
Analyze the codebase and identify performance bottlenecks.
Focus on database queries and API calls.
```

### Medium Freedom Example

```markdown
for each endpoint in api_routes:
    measure_response_time(endpoint, iterations=100)
    if avg_time > threshold:
        flag_for_review(endpoint)
```

### Low Freedom Example

```bash
# Run exactly as written
python scripts/benchmark.py --routes api_routes.json --threshold 200ms
```
