---
name: security
description: "Security-focused code review. Scans for OWASP Top 10, exposed secrets, injection vulnerabilities, auth issues. Use for security audits or thorough reviews."
---

# Security Review

Security-focused code review targeting OWASP Top 10 vulnerabilities and common security issues.

## Invocation

```bash
/code-review:security                    # Security audit of uncommitted changes
/code-review:security src/               # Audit specific directory
/code-review:security --full             # Full codebase security audit
```

## Scope

### Always Check (Every Review)

| Category | What to Find |
|----------|--------------|
| **Secrets** | API keys, tokens, passwords in code or config |
| **Injection** | SQL injection, command injection, XSS |
| **Auth Issues** | Missing authentication, broken authorization |
| **Data Exposure** | Sensitive data in logs, error messages, responses |

### Thorough Mode (Full Audit)

| Category | What to Find |
|----------|--------------|
| **OWASP Top 10** | Complete vulnerability assessment |
| **Cryptography** | Weak algorithms, hardcoded keys, improper storage |
| **Session Management** | Insecure cookies, session fixation |
| **Dependencies** | Known vulnerable packages |

## Detection Patterns

### A. Exposed Secrets (BLOCKER)

```bash
# Search for potential secrets
grep -rn "api.key\|apiKey\|api_key" --include="*.ts" --include="*.js"
grep -rn "secret\|token\|password\|credential" --include="*.ts" --include="*.js"
grep -rn "sk_live\|pk_live\|ghp_\|gho_" --include="*"
```

**Red flags:**
- Hardcoded API keys or tokens
- Credentials in environment checks (`process.env.API_KEY || "default_key"`)
- Secrets in test fixtures that aren't clearly marked
- Base64-encoded secrets
- Private keys in repository

**Confidence:** 95-100 for confirmed secrets, BLOCKER status

### B. Injection Vulnerabilities (BLOCKER)

#### SQL Injection
```typescript
// BAD - direct string concatenation
const query = `SELECT * FROM users WHERE id = ${userId}`;

// GOOD - parameterized query
const query = `SELECT * FROM users WHERE id = $1`;
```

#### Command Injection
```typescript
// BAD - user input in shell command
exec(`ls ${userInput}`);

// GOOD - use array form with no shell
execFile('ls', [validatedPath]);
```

#### XSS
```typescript
// BAD - unescaped user content
element.innerHTML = userContent;

// GOOD - text content or sanitization
element.textContent = userContent;
```

**Confidence:** 90-100 for confirmed injection paths, BLOCKER status

### C. Authentication & Authorization

**Missing authentication:**
- Endpoints without auth middleware
- Public routes exposing sensitive operations
- Inconsistent auth checks across similar endpoints

**Broken authorization:**
- Missing ownership checks
- Role-based access without verification
- IDOR vulnerabilities (direct object reference)

```typescript
// BAD - no ownership check
app.delete('/api/posts/:id', async (req, res) => {
  await Post.delete(req.params.id);  // Anyone can delete any post
});

// GOOD - verify ownership
app.delete('/api/posts/:id', async (req, res) => {
  const post = await Post.findById(req.params.id);
  if (post.authorId !== req.user.id) return res.status(403).send('Forbidden');
  await post.delete();
});
```

**Confidence:** 85-95 depending on context

### D. Data Exposure

**Sensitive data in logs:**
```typescript
// BAD
console.log('Login attempt:', { email, password });

// GOOD
console.log('Login attempt:', { email, password: '[REDACTED]' });
```

**Sensitive data in error messages:**
```typescript
// BAD
throw new Error(`Invalid credentials for ${email}: ${password}`);

// GOOD
throw new Error('Invalid credentials');
```

**Sensitive data in API responses:**
```typescript
// BAD - returning full user object
return res.json(user);  // Might include password hash, tokens, etc.

// GOOD - explicit field selection
return res.json({ id: user.id, name: user.name, email: user.email });
```

**Confidence:** 80-90 depending on data sensitivity

### E. Cryptography Issues

**Weak algorithms:**
- MD5 or SHA1 for security purposes
- ECB mode for AES
- Short key lengths

**Improper key storage:**
- Hardcoded encryption keys
- Keys in version control
- Keys in client-side code

**Confidence:** 85-95

### F. Dependency Vulnerabilities

```bash
# Check for known vulnerabilities
npm audit --json 2>/dev/null | jq '.vulnerabilities | length'

# Check for outdated security-critical packages
npm outdated | grep -E "express|helmet|jsonwebtoken|bcrypt"
```

**Confidence:** Based on CVE severity

## Output Format

```json
{
  "scope": "security",
  "files_checked": ["src/api/users.ts", "src/auth/login.ts"],
  "vulnerabilities": [
    {
      "severity": "critical",
      "category": "injection",
      "type": "sql-injection",
      "file": "src/api/users.ts",
      "line": 45,
      "code": "const query = `SELECT * FROM users WHERE id = ${id}`",
      "issue": "User input directly interpolated into SQL query",
      "attack_vector": "Attacker can inject SQL: id=1; DROP TABLE users;--",
      "confidence": 98,
      "fix": "Use parameterized queries: db.query('SELECT * FROM users WHERE id = $1', [id])",
      "cwe": "CWE-89",
      "owasp": "A03:2021 Injection"
    },
    {
      "severity": "critical",
      "category": "secrets",
      "type": "exposed-api-key",
      "file": "src/config.ts",
      "line": 12,
      "code": "const API_KEY = 'sk_live_abc123...'",
      "issue": "Production API key hardcoded in source code",
      "attack_vector": "Anyone with repo access can use this key",
      "confidence": 100,
      "fix": "Move to environment variable, rotate the exposed key immediately",
      "cwe": "CWE-798"
    }
  ],
  "blockers": [
    {
      "type": "security",
      "severity": "critical",
      "file": "src/api/users.ts",
      "issue": "SQL injection vulnerability must be fixed before merge"
    }
  ],
  "passed": false,
  "summary": "Found 2 critical security vulnerabilities. Must fix before merge."
}
```

## Severity Levels

| Severity | Criteria | Action |
|----------|----------|--------|
| **critical** | Remote code execution, data breach, secret exposure | BLOCKER - fix immediately |
| **high** | Auth bypass, injection possible but limited | BLOCKER - fix before merge |
| **medium** | Information disclosure, session issues | Flag - fix soon |
| **low** | Minor information leakage, best practice violations | Note - fix when convenient |

## Integration

### With Code Reviewer

Security review is part of thorough mode:

```markdown
Task(
  subagent_type="code-review:reviewer",
  prompt="THOROUGH review - include security audit"
)
```

### Standalone Security Audit

Run independently for dedicated security review:

```bash
/code-review:security --full    # Full codebase audit
```

## What to Flag

**ALWAYS BLOCK (confidence ≥90):**
- Exposed secrets/credentials
- SQL/command/XSS injection
- Missing authentication on sensitive endpoints
- Broken authorization checks

**FLAG (confidence 80-89):**
- Sensitive data in logs
- Weak cryptography
- Insecure session handling
- CSRF vulnerabilities

**NOTE (confidence 70-79):**
- Missing security headers
- Verbose error messages
- Outdated dependencies without known CVEs

## Remember

- Security issues are BLOCKERS by default
- When in doubt, flag it - false positive is better than missed vulnerability
- Provide specific fix recommendations
- Reference CWE/OWASP where applicable
- Exposed secrets require immediate rotation, not just code fix
