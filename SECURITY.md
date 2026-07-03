# Security Policy

## Supported baseline

Only the latest `main` branch baseline is actively supported for security updates.

## Reporting a vulnerability

If you discover a security issue:

1. Do not open a public issue with exploit details.
2. Report vulnerabilities via [GitHub private vulnerability reporting](https://github.com/ulises-jeremias/agentic-workstation/security/advisories/new) or email the maintainer.
3. Include reproduction details, impact, and affected files.

## Security principles in this repository

- No credentials are stored in source control.
- MCP templates use environment-variable placeholders only.
- CI includes repository-level security scanners via MegaLinter v9.
