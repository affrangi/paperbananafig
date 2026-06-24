---
name: paperbanana
description: Generate publication-quality academic figures — methodology diagrams and statistical plots — from text and data via the paperbanana MCP server. Use whenever the user wants to create a research figure, methodology/architecture/pipeline diagram, schematic, a statistical plot or chart from data, a full-paper figure package, or asks to visualize a method for a paper, poster, or slides.
---

# PaperBanana Figures

Produce publication-ready academic figures from a text description or a dataset, using the **paperbanana** MCP server. PaperBanana runs a multi-agent pipeline (Retriever → Planner → Stylist, then a Visualizer ↔ Critic refinement loop) and returns rendered image files plus metadata.

Deliver the **file path(s)** to the rendered figure(s) inline in chat, with a one-line summary of what was made and the settings assumed.

## Prerequisite: the MCP server

The tools appear as `mcp__paperbanana__*` (e.g. `mcp__paperbanana__generate_diagram`). If they are absent, the server is not registered — tell the user to add it and stop:

```bash
claude mcp add paperbanana -e GOOGLE_API_KEY=your-key -- uvx --from "paperbanana[mcp]" paperbanana-mcp
```

- `GOOGLE_API_KEY` enables the Gemini provider (used by the command above).
- Depending on the configured provider, `OPENAI_API_KEY` may also be required. If a call fails on auth/provider, surface the error and ask the user which provider/key to use rather than guessing.

## Workflow

1. **Read the brief.** Capture what the figure must show: for a diagram, the methodology/architecture text; for a plot, the data (JSON/CSV) and the analytical intent. Note any style, domain, or venue constraints.
2. **Fill gaps with stated assumptions — don't interrogate.** Pick sensible defaults (e.g. clean vector style, neutral palette) and state them in one line so the user can override.
3. **Pick the tool** (see decision guide below).
4. **Generate.** Call the tool; it runs in a worker thread and returns JSON with the output paths (`final_image_path`, `run_dir`, `metadata_path`).
5. **Evaluate / refine.** Inspect the result. To improve it, use the matching `continue_*` tool against the returned `run_dir` with specific feedback — do **not** start a fresh run. Optionally score it with `evaluate_diagram` / `evaluate_plot` against a reference.
6. **Present** the final image path(s) and a brief caption. Mention `run_dir` so the user can request further refinements.

## Tool decision guide

| Need | Tool |
|---|---|
| One methodology / architecture / pipeline diagram from text | `generate_diagram(text_context, caption)` |
| One statistical plot from data + intent | `generate_plot(...)` (JSON/CSV data + intent description) |
| Refine an existing diagram run | `continue_diagram(run_dir, feedback)` |
| Refine an existing plot run | `continue_plot(run_dir, feedback)` |
| General refinement of any run directory | `continue_run(run_dir, ...)` |
| Score a diagram/plot vs a human reference | `evaluate_diagram` / `evaluate_plot` |
| Plan/generate a whole paper's figure set | `orchestrate_figures(...)` — use `dry_run=True` to plan without API spend |
| Many diagrams/plots from a manifest | `batch_diagrams(manifest)` / `batch_plots(manifest)` |
| Improve retrieval quality first | `download_references()` |

See `references/paperbanana-mcp.md` for full parameter and output details.

## Authoring good prompts

- **Diagrams (`text_context`):** describe the method as a sequence of stages/components and how they connect — inputs, blocks, arrows, outputs. Name the desired visual style (boxes-and-arrows schematic, layered architecture, swimlane) and palette. The `caption` is the figure caption / title.
- **Plots (`generate_plot`):** state the chart type only if you have a strong reason; otherwise let the intent description ("show accuracy vs. training steps for three models") drive the choice. Provide clean, well-labelled data.

## Conforming output (when a target spec is given)

PaperBanana chooses its own canvas; it does not take an aspect-ratio argument. If the user needs an exact size, DPI, format, or aspect ratio (e.g. a single-column figure, a square thumbnail, 300 DPI TIFF), open the returned `final_image_path` and crop/resize/convert it to spec as a post-step, then hand over the conformed file.

## Pre-delivery checklist

- [ ] Correct tool chosen for the request (diagram vs plot vs orchestrate/batch)
- [ ] Assumptions (style, palette, defaults) stated in one line
- [ ] Output file path(s) reported; `run_dir` surfaced for refinement
- [ ] Refinements done via `continue_*`, not fresh runs
- [ ] Output conformed to any explicit size/format/DPI spec
