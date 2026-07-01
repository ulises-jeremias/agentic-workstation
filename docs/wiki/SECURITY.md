# Security

> Security practices and vulnerability reporting for the workstation platform.

---

## Principles

- **No credentials** are stored in source control
- **Secrets** are consumed via environment variables only
- **MCP templates** ship with placeholder values — never real tokens
- **CI** includes security scanners via MegaLinter v9

---

## Secret management

Store secrets in `~/.config/agentic-workstation/env.d/`:

```bash
# Example: Jira credentials
cat > ~/.config/agentic-workstation/env.d/jira.env << 'EOF'
export JIRA_SITE_URL="https://your-company.atlassian.net"
export JIRA_EMAIL="you@company.com"
export JIRA_API_TOKEN="your-api-token"
EOF
```

Load with `dots-loadenv` or source directly.

---

## Reporting vulnerabilities

1. **Do not** open a public issue with exploit details
2. Contact the agentic-workstation Technology team through internal channels
3. Include reproduction details, impact, and affected files

---

## CI security checks

| Check | Workflow |
|-------|---------|
| Secret scanning | `security-scan.yml` |
| Dependency audit | `dependabot.yml` |
| Code quality | `megalinter-v9.yml` |
| Pre-commit hooks | `pre-commit.yml` |

---

**Canonical doc:** [`SECURITY.md`](https://github.com/ulises-jeremias/agentic-workstation/blob/main/SECURITY.md)
