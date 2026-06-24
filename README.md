# paperbanana

A self-contained Claude skill for generating publication-quality academic figures — methodology diagrams and statistical plots — from text and data, via the [paperbanana](https://github.com/llmsresearch/paperbanana) MCP server.

## Layout

- `SKILL.md` — the skill: workflow, tool decision guide, prompting and output-conforming guidance.
- `references/paperbanana-mcp.md` — full MCP reference: registration, providers, the 11 tools, outputs.

## Setup

Register the MCP server (Gemini provider shown):

```bash
claude mcp add paperbanana -e GOOGLE_API_KEY=your-key -- uvx --from "paperbanana[mcp]" paperbanana-mcp
```

Then the tools are available as `mcp__paperbanana__*`. See `SKILL.md` to use them.

This project is independent and shares nothing with other skills in the repository.
