# Creative Workstation

Optional machine provisioning for AI-assisted creative production
(video, motion, image, audio) with Agent Toolkit Creative Studio.

**Layering:** this repository (L1) only makes applications available.
Skills, MCP registry entries, agent definitions and workflows live in
[agent-toolkit](https://github.com/ulises-jeremias/agent-toolkit)
(`agent-toolkit-creative-studio` product, ADR-046). Personal presets,
audio-interface routing and project files never enter this repository.

## Enable

```bash
# Interactive: pick the `creative` profile, or `custom` + creative group
chezmoi init
# Unattended:
WORKSTATION_PROFILE=creative chezmoi init --force
chezmoi apply
```

The `creative` profile enables groups: core, python, ai,
skills_productivity, creative. The creative group
(`run_onchange_48-install-creative-tooling.sh.tmpl`) installs, when
missing: ffmpeg (with ffprobe), MLT/`melt`, Kdenlive, Blender, and the
Kdenlive MCP server (`mcp-kdenlive` via pipx — note the PyPI name).

Package names are translated per manager (Arch `mlt`, Debian `melt`;
Fedora users may need RPM Fusion for full ffmpeg/Kdenlive; Homebrew
covers ffmpeg/Blender only). Anything without a safe mapping is warned
about, never guessed.

## Diagnose

```bash
dots-creative-doctor          # human report
dots-creative-doctor --json   # machine-readable tool states
kdenlive-mcp diagnose         # deep check from the MCP server itself
```

States follow ADR-046 (`available`, `unsupported`, …). Optional
applications (GIMP, Krita, Inkscape, OBS, REAPER) are reported but never
installed or configured by the creative group; REAPER is proprietary and
stays a manual, licensed install. Nothing here enables recording,
streaming or microphone access.

## Resource safety

Creative renders are heavy. Check `dots-creative-doctor` resources
(CPU/RAM/disk/GPU+NVENC) before long jobs and bound them, for example:

```bash
systemd-run --user --scope -p MemoryMax=6G -p MemorySwapMax=0 \
  horneroctl studio jobs submit --adapter melt-render \
  --input edit.kdenlive --output final.mp4 --execute --yes
```

Do not copy GPU-specific tuning (e.g. the LM Studio group's RTX 3060
VRAM budget) to machines with different hardware; those values are
host-specific starting points, not universal settings.

## Disable / uninstall

Re-run `chezmoi init` without the creative group (stops future
provisioning; installed system packages remain yours to remove with
your package manager), `pipx uninstall mcp-kdenlive`, and remove the
`agent-toolkit-creative-studio` product via Agent Toolkit. Creative
projects and native editor files are never deleted.
