# Figma Integration

> Design context, screenshots, variables, and assets for AI-assisted workflows.

---

## Best path

Use the Figma MCP template plus the bundled Figma skill family.

## Setup

```bash
mkdir -p ~/.config/agentic-workstation/env.d
cat >> ~/.config/agentic-workstation/env.d/figma.env <<'EOF'
export FIGMA_OAUTH_TOKEN="<paste-token-here>"
export FIGMA_REGION="us-east-1"
EOF
chmod 600 ~/.config/agentic-workstation/env.d/figma.env
```

## Register the MCP server

Add the Figma MCP entry to your AI tool config using the template in `MCP`.

## What it enables

- Read design context
- Inspect variables and assets
- Translate designs into implementation guidance

## AI workflows

- `figma` for the MCP entry point
- `figma-implement-design` for design-to-code work
- `figma-code-connect-components` for mapping components
- `figma-create-design-system-rules` for repo-specific design rules

## Verify

```bash
dots-doctor
dots-skills list
```

## See also

- [MCP Templates](MCP)
- [Troubleshooting](INTEGRATION_TROUBLESHOOTING)
