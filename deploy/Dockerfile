# Remote paperbanana MCP server for Google Cloud Run.
#
# paperbanana-mcp speaks stdio only, so we wrap it with supergateway, which
# exposes it over Streamable HTTP on $PORT. Needs both uv (Python, for
# paperbanana) and Node (for supergateway).

FROM python:3.12-slim

# Node 20 (supergateway) + uv (paperbanana)
RUN apt-get update \
    && apt-get install -y --no-install-recommends curl ca-certificates \
    && curl -fsSL https://deb.nodesource.com/setup_20.x | bash - \
    && apt-get install -y --no-install-recommends nodejs \
    && rm -rf /var/lib/apt/lists/*
RUN curl -LsSf https://astral.sh/uv/install.sh | sh
ENV PATH="/root/.local/bin:${PATH}"

# Cloud Run injects $PORT (default 8080). Bind to it.
ENV PORT=8080

# stdio MCP server -> Streamable HTTP. Endpoint: /mcp
# (swap to "--outputTransport sse" if your client needs SSE; endpoint becomes /sse)
CMD npx -y supergateway \
      --stdio "uvx --from 'paperbanana[mcp]' paperbanana-mcp" \
      --outputTransport streamableHttp \
      --port $PORT
