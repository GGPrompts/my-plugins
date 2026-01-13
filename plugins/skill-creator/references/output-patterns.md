# Output Patterns

Patterns for generating consistent, quality output from skills.

## Template Pattern

Use templates when output format must be precise and consistent.

### Strict Requirements

For API responses, data formats, or compliance needs:

```markdown
## Required Output Structure

1. **Analysis Title** - Clear, descriptive heading
2. **Executive Summary** - 2-3 sentence overview
3. **Key Findings** - Bulleted list with supporting data
4. **Recommendations** - Specific, actionable items
```

### Flexible Guidance

For situations where adaptation is beneficial:

```markdown
## Output Guidelines

Use this format as a sensible default, adjusting based on what you discover:

- Include sections that add value for this specific analysis
- Omit sections that don't apply
- Tailor recommendations to the specific context
```

## Examples Pattern

Output quality often depends on seeing concrete input/output pairs. Examples communicate desired style better than descriptions.

### Example: Commit Messages

**Input:** "Added user authentication with JWT tokens"

**Output:**
```
feat(auth): add JWT-based user authentication

Implement secure token-based authentication:
- JWT generation on login with 24h expiry
- Middleware for protected routes
- Refresh token rotation
```

**Input:** "Fixed bug where dates showed wrong timezone"

**Output:**
```
fix(dates): correct timezone handling in date formatter

Convert all dates to UTC before display, then apply
user's local timezone. Fixes incorrect times for
users outside server timezone.
```

### When to Use Examples

- Style/tone requirements are hard to describe
- Format has specific conventions
- Quality bar is easier to show than explain
- Multiple valid approaches exist but one is preferred
