# LLM Providers

> How the Dev Companion selects and uses AI models.

---

## Provider priority

The runner automatically selects providers in this order:

| Priority | Provider | Type | Cost | Requirements |
|----------|----------|------|------|--------------|
| 1 | **OpenCode (big-pickle)** | Local | Free | `opencode` installed |
| 2 | Ollama | Local | Free | `ollama` installed + models |
| 3 | Anthropic (Claude) | Cloud | Paid | `ANTHROPIC_API_KEY` |
| 4 | OpenAI | Cloud | Paid | `OPENAI_API_KEY` |

---

## Zero-config experience

For most developers:

1. Install OpenCode → Done
2. Run jobs → Works immediately with `big-pickle`

No API keys required. No configuration files.

---

## Advanced: Ollama (Local GPU)

```bash
brew install ollama           # macOS
curl -fsSL https://ollama.com/install.sh | sh  # Linux

ollama pull llama3.2          # pull a model
# The runner auto-detects and uses it
```

---

## Advanced: Cloud providers

```bash
export ANTHROPIC_API_KEY="sk-ant-..."   # Claude
export OPENAI_API_KEY="sk-..."          # OpenAI
```

Cloud providers are used only if no free local provider is available.

---

## Debugging

```bash
DOTS_WORKSTATION_LLM_DEBUG=1 dots-devcompanion run-once   # debug logging
opencode --version                           # check OpenCode
ollama list                                  # check Ollama models
```

---

## Fallback behavior

| Scenario | Behavior |
|----------|----------|
| No providers available | Generates skeleton plan |
| Provider times out | Writes error in artifacts |
| Provider returns invalid response | Falls back to skeleton |

---

**Canonical doc:** [`docs/DEV_COMPANION_LLM.md`](https://github.com/ulises-jeremias/agentic-workstation/blob/main/docs/DEV_COMPANION_LLM.md)
