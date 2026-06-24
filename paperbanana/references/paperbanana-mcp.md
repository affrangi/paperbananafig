# PaperBanana MCP reference

Upstream: [llmsresearch/paperbanana](https://github.com/llmsresearch/paperbanana) — an open-source implementation/extension of Google Research's PaperBanana for automated academic figures, diagrams, and research visuals.

## Registration

```bash
claude mcp add paperbanana -e GOOGLE_API_KEY=your-key -- uvx --from "paperbanana[mcp]" paperbanana-mcp
```

Equivalent JSON client config:

```json
{
  "mcpServers": {
    "paperbanana": {
      "command": "uvx",
      "args": ["--from", "paperbanana[mcp]", "paperbanana-mcp"],
      "env": { "GOOGLE_API_KEY": "your-google-api-key" }
    }
  }
}
```

`uvx` runs the server without a local clone. No persistent install needed.

## Environment / providers

- `GOOGLE_API_KEY` — Gemini provider (matches the command above).
- `OPENAI_API_KEY` — required when an OpenAI/Azure provider is configured.
- Provider support spans OpenAI (GPT + GPT-Image), Azure OpenAI / Foundry, Google Gemini, and Atlas Cloud.

## Pipeline

- **Phase 1 — linear planning:** Retriever → Planner → Stylist.
- **Phase 2 — refinement loop:** Visualizer ↔ Critic for `T = 3` rounds by default.
- Long runs execute in worker threads so the MCP server does not block; progress is logged via structlog.

## Tools (11)

| Tool | Purpose | Key inputs |
|---|---|---|
| `generate_diagram` | Methodology diagram from text | `text_context`, `caption` |
| `generate_plot` | Statistical plot from data | JSON/CSV data + intent description |
| `continue_diagram` | Refine a prior diagram run | `run_dir`, feedback |
| `continue_plot` | Refine a prior plot run | `run_dir`, feedback |
| `continue_run` | General refinement of any run dir | `run_dir`, optional critic feedback |
| `evaluate_diagram` | Compare a diagram to a human reference (4 dimensions) | generated + reference |
| `evaluate_plot` | Compare a plot to a human reference | generated + reference |
| `orchestrate_figures` | Plan/generate a full-paper figure package | manifest/spec; `dry_run=True` to plan |
| `batch_diagrams` | Run a diagram batch from a manifest | manifest path |
| `batch_plots` | Run a plot batch from a manifest | manifest path |
| `download_references` | Download expanded reference set for stronger retrieval | — |

## Outputs

- `generate_diagram` returns JSON with `final_image_path`, `run_dir`, and `metadata_path`. Image formats are PNG / JPEG / WebP.
- With parallel candidate generation, outputs land in `candidates/cand_<i>/`.
- Batch/orchestration tools return pretty-printed JSON pointing at `batch_report.json`, `figure_package.json`, and per-item summaries.
- Validation errors carry an `error` field and `"strict_success": false`.

## Notes & prerequisites

- `continue_*` tools require a `run_input.json` produced by a prior generation call — always refine an existing `run_dir`, don't start over.
- Batch and orchestration tools need a manifest path.
- Use `dry_run=True` on `orchestrate_figures` to plan a figure set without spending API calls.
- PaperBanana takes no aspect-ratio argument; conform to an exact size/format/DPI as a post-processing step on `final_image_path`.
