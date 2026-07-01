#!/usr/bin/env python3
# /// script
# requires-python = ">=3.10"
# dependencies = []
# ///
from __future__ import annotations

import json
import pathlib
import sys
from typing import Any

try:
    import yaml
except ImportError:
    yaml = None

REPO_ROOT = pathlib.Path(__file__).resolve().parent.parent
CATALOG_REPO = REPO_ROOT / "home" / "dot_local" / "share" / "agentic-workstation" / "skills" / "skill-catalog.yaml"
CATALOG_USER = pathlib.Path.home() / ".local" / "share" / "agentic-workstation" / "skills" / "skill-catalog.yaml"
SKILLS_DIR = REPO_ROOT / "home" / "dot_local" / "share" / "agentic-workstation" / "skills"
OUTPUT_DIR = REPO_ROOT / "docs" / "skills"
OUTPUT_FILE = OUTPUT_DIR / "index.html"

TOOLS = ["universal", "claude-code", "opencode", "cursor", "windsurf", "copilot-cli", "pi"]


def load_catalog() -> list[dict[str, Any]]:
    path = CATALOG_REPO if CATALOG_REPO.exists() else CATALOG_USER
    if yaml is None:
        print("PyYAML is required", file=sys.stderr)
        sys.exit(1)
    if not path.exists():
        print(f"Catalog not found at {path}", file=sys.stderr)
        sys.exit(1)
    text = path.read_text(encoding="utf-8")
    data = yaml.safe_load(text)
    return data.get("skills", []) if isinstance(data, dict) else []


def load_skill_json(name: str) -> dict[str, Any]:
    f = SKILLS_DIR / name / "skill.json"
    if not f.exists():
        return {}
    try:
        return json.loads(f.read_text(encoding="utf-8"))
    except json.JSONDecodeError:
        return {}


def get_compatible_tools(entry: dict[str, Any], name: str) -> list[str]:
    bundled = entry.get("bundled", True)
    manifest = load_skill_json(name)
    compat = manifest.get("compatibility", {})
    supported = [t for t in TOOLS if compat.get(t, {}).get("supported")]
    if supported:
        return supported
    if bundled:
        return ["universal"]
    return []


DOMAIN_COLORS = {
    "orchestration": "#a371f7",
    "workflow": "#58a6ff",
    "delivery": "#3fb950",
    "forge": "#f0883e",
    "assessment": "#d2a8ff",
    "data": "#79c0ff",
    "ui": "#ff7b72",
    "slack": "#56d364",
    "clickup": "#f2cc60",
    "jira": "#58a6ff",
    "confluence": "#79c0ff",
    "figma": "#ff7b72",
    "linear": "#bc8cff",
    "testing": "#3fb950",
    "rd": "#ffa657",
    "learning": "#d2a8ff",
    "workstation": "#8b949e",
    "companion": "#f778ba",
    "governance": "#d29922",
    "operations": "#ff7b72",
    "agents": "#a371f7",
    "llm": "#3fb950",
    "other": "#8b949e",
}


def generate_html(skills: list[dict[str, Any]]) -> str:
    rows = []
    for entry in skills:
        name = entry.get("name", "")
        domain = entry.get("domain", "other")
        responsibility = entry.get("responsibility", "")
        compatible = get_compatible_tools(entry, name)
        tools_display = ", ".join(compatible) if compatible else "\u2014"

        domain_color = DOMAIN_COLORS.get(domain, "#8b949e")

        rows.append(
            f'      <tr data-name="{name.lower()}" '
            f'data-domain="{domain.lower()}" '
            f'data-resp="{responsibility.lower()}" '
            f'data-tools="{",".join(compatible)}">\n'
            f'        <td class="cell-name"><code>{name}</code></td>\n'
            f'        <td><span class="tag" style="--tag-color:{domain_color}">{domain}</span></td>\n'
            f'        <td class="cell-resp">{responsibility}</td>\n'
            f'        <td class="cell-tools">{tools_display}</td>\n'
            f"      </tr>"
        )

    table_rows = "\n".join(rows)

    return f"""<!DOCTYPE html>
<html lang="en">
<head>
  <meta charset="UTF-8">
  <meta name="viewport" content="width=device-width, initial-scale=1.0">
  <title>agentic-workstation Skill Catalog</title>
  <style>
    :root {{
      --bg: #0d1117;
      --surface: #161b22;
      --border: #30363d;
      --text: #e6edf3;
      --text-muted: #8b949e;
      --accent: #a371f7;
      --input-bg: #0d1117;
      --input-border: #30363d;
    }}
    * {{ margin: 0; padding: 0; box-sizing: border-box; }}
    body {{
      font-family: -apple-system, BlinkMacSystemFont, "Segoe UI", Helvetica, Arial, sans-serif;
      background: var(--bg);
      color: var(--text);
      line-height: 1.6;
      padding: 24px;
    }}
    .container {{ max-width: 1200px; margin: 0 auto; }}
    header {{ margin-bottom: 28px; }}
    h1 {{
      font-size: 1.75rem;
      font-weight: 600;
      margin-bottom: 4px;
      color: var(--accent);
    }}
    .subtitle {{ color: var(--text-muted); font-size: 0.875rem; }}
    .controls {{
      display: flex;
      gap: 12px;
      margin-bottom: 20px;
      flex-wrap: wrap;
    }}
    #search {{
      flex: 1;
      min-width: 200px;
      padding: 10px 14px;
      background: var(--input-bg);
      border: 1px solid var(--input-border);
      border-radius: 8px;
      color: var(--text);
      font-size: 0.9rem;
      outline: none;
      transition: border-color 0.2s;
    }}
    #search:focus {{ border-color: var(--accent); }}
    #search::placeholder {{ color: var(--text-muted); }}
    .filter-group {{
      display: flex;
      gap: 8px;
      flex-wrap: wrap;
      align-items: center;
    }}
    .filter-group label {{
      font-size: 0.8rem;
      color: var(--text-muted);
    }}
    select {{
      padding: 10px 12px;
      background: var(--input-bg);
      border: 1px solid var(--input-border);
      border-radius: 8px;
      color: var(--text);
      font-size: 0.85rem;
      outline: none;
      cursor: pointer;
    }}
    select:focus {{ border-color: var(--accent); }}
    .count {{
      font-size: 0.85rem;
      color: var(--text-muted);
      margin-bottom: 12px;
    }}
    .table-wrap {{
      overflow-x: auto;
      border: 1px solid var(--border);
      border-radius: 10px;
    }}
    table {{
      width: 100%;
      border-collapse: collapse;
      font-size: 0.875rem;
    }}
    th {{
      text-align: left;
      padding: 12px 16px;
      background: var(--surface);
      border-bottom: 1px solid var(--border);
      font-weight: 600;
      white-space: nowrap;
      cursor: pointer;
      user-select: none;
    }}
    th:hover {{ color: var(--accent); }}
    th .sort-icon {{ margin-left: 4px; opacity: 0.4; }}
    th.sorted .sort-icon {{ opacity: 1; }}
    td {{
      padding: 10px 16px;
      border-bottom: 1px solid var(--border);
      vertical-align: middle;
    }}
    tr:last-child td {{ border-bottom: none; }}
    tr:hover td {{ background: rgba(163, 113, 247, 0.04); }}
    .cell-name code {{
      font-family: "SF Mono", "Cascadia Code", "Fira Code", "Consolas", monospace;
      font-size: 0.8rem;
      background: rgba(163, 113, 247, 0.1);
      padding: 2px 6px;
      border-radius: 4px;
    }}
    .tag {{
      display: inline-block;
      padding: 2px 10px;
      border-radius: 12px;
      font-size: 0.75rem;
      font-weight: 500;
      background: rgba(128, 128, 128, 0.1);
      border: 1px solid var(--tag-color, var(--border));
      color: var(--tag-color, var(--text));
    }}
    .cell-tools {{
      font-size: 0.8rem;
      color: var(--text-muted);
    }}
    .no-results {{
      text-align: center;
      padding: 48px 16px;
      color: var(--text-muted);
    }}
    footer {{
      margin-top: 32px;
      font-size: 0.8rem;
      color: var(--text-muted);
      text-align: center;
    }}
    footer code {{
      background: rgba(128,128,128,0.1);
      padding: 1px 5px;
      border-radius: 3px;
      font-size: 0.75rem;
    }}
    @media (max-width: 640px) {{
      body {{ padding: 16px; }}
      h1 {{ font-size: 1.35rem; }}
      th, td {{ padding: 8px 10px; }}
      .controls {{ flex-direction: column; }}
      #search {{ min-width: unset; }}
    }}
  </style>
</head>
<body>
  <div class="container">
    <header>
      <h1>agentic-workstation Skill Catalog</h1>
      <p class="subtitle">{len(skills)} skills indexed</p>
    </header>

    <div class="controls">
      <input type="text" id="search" placeholder="Search by name, domain, or keywords\u2026" autofocus>
      <div class="filter-group">
        <label for="domain-filter">Domain</label>
        <select id="domain-filter">
          <option value="">All</option>
        </select>
      </div>
      <div class="filter-group">
        <label for="resp-filter">Type</label>
        <select id="resp-filter">
          <option value="">All</option>
          <option value="HOW">HOW</option>
          <option value="WHAT">WHAT</option>
        </select>
      </div>
    </div>

    <p class="count" id="count">{len(skills)} skills shown</p>

    <div class="table-wrap">
      <table>
        <thead>
          <tr>
            <th data-col="name">Name <span class="sort-icon">\u25b2</span></th>
            <th data-col="domain">Domain <span class="sort-icon">\u25b2</span></th>
            <th data-col="resp">Responsibility <span class="sort-icon">\u25b2</span></th>
            <th data-col="tools">Compatible Tools <span class="sort-icon">\u25b2</span></th>
          </tr>
        </thead>
        <tbody id="tbody">
{table_rows}
        </tbody>
      </table>
    </div>

    <div id="no-results" class="no-results" style="display:none">
      No skills match your filters.
    </div>

    <footer>
      <p>Auto-generated from <code>skill-catalog.yaml</code>. Run <code>python3 scripts/generate-skill-index.py</code> to regenerate.</p>
    </footer>
  </div>

  <script>
    (function() {{
      var search = document.getElementById('search');
      var domainFilter = document.getElementById('domain-filter');
      var respFilter = document.getElementById('resp-filter');
      var tbody = document.getElementById('tbody');
      var count = document.getElementById('count');
      var noResults = document.getElementById('no-results');
      var rows = Array.from(tbody.querySelectorAll('tr'));

      var sortState = {{ col: 'name', asc: true }};

      var domains = [...new Set(rows.map(function(r) {{ return r.dataset.domain; }}))].sort();
      domains.forEach(function(d) {{
        var opt = document.createElement('option');
        opt.value = d;
        opt.textContent = d;
        domainFilter.appendChild(opt);
      }});

      function filterAndSort() {{
        var q = search.value.toLowerCase().trim();
        var domain = domainFilter.value;
        var resp = respFilter.value;

        var visible = rows.filter(function(row) {{
          var name = row.dataset.name;
          var dom = row.dataset.domain;
          var r = row.dataset.resp;
          var tools = row.dataset.tools;

          var text = [name, dom, r, tools].join(' ');
          if (q && text.indexOf(q) === -1) return false;
          if (domain && dom !== domain) return false;
          if (resp && r !== resp) return false;
          return true;
        }});

        var col = sortState.col;
        var asc = sortState.asc;
        visible.sort(function(a, b) {{
          var va = (a.dataset[col] || '').toLowerCase();
          var vb = (b.dataset[col] || '').toLowerCase();
          if (va < vb) return asc ? -1 : 1;
          if (va > vb) return asc ? 1 : -1;
          return 0;
        }});

        tbody.innerHTML = '';
        visible.forEach(function(r) {{ tbody.appendChild(r); }});

        count.textContent = visible.length + ' skill' + (visible.length !== 1 ? 's' : '') + ' shown';
        noResults.style.display = visible.length === 0 ? 'block' : 'none';

        document.querySelectorAll('th').forEach(function(th) {{
          th.classList.toggle('sorted', th.dataset.col === col);
          var icon = th.querySelector('.sort-icon');
          if (th.dataset.col === col) {{
            icon.textContent = asc ? '\u25b2' : '\u25bc';
          }} else {{
            icon.textContent = '\u25b2';
          }}
        }});
      }}

      search.addEventListener('input', filterAndSort);
      domainFilter.addEventListener('change', filterAndSort);
      respFilter.addEventListener('change', filterAndSort);

      document.querySelectorAll('th[data-col]').forEach(function(th) {{
        th.addEventListener('click', function() {{
          var col = this.dataset.col;
          if (sortState.col === col) {{
            sortState.asc = !sortState.asc;
          }} else {{
            sortState.col = col;
            sortState.asc = true;
          }}
          filterAndSort();
        }});
      }});

      filterAndSort();
    }})();
  </script>
</body>
</html>"""


def main() -> None:
    skills = load_catalog()
    if not skills:
        print("No skills found in catalog.", file=sys.stderr)
        sys.exit(1)

    html = generate_html(skills)
    OUTPUT_DIR.mkdir(parents=True, exist_ok=True)
    OUTPUT_FILE.write_text(html, encoding="utf-8")
    print(f"  Written {OUTPUT_FILE.relative_to(REPO_ROOT)} ({len(skills)} skills)")


if __name__ == "__main__":
    main()
