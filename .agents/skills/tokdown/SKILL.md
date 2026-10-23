---
name: tokdown
description: Cuts LLM prompt tokens and context consumption by 50% to 70% using schema tabularization, TOON notation, and BPE estimation. Use when handling large JSON, YAML, database records, API outputs, or long context payloads.
---

# TokDown Skill for AI Agents (Antigravity)

Use this skill whenever you are about to inject large structured data (JSON, YAML, database rows, API responses) into an LLM prompt or context window.

## When to Use

1. **Database / ORM Queries**: When passing arrays of records or user lists to an LLM.
2. **API Responses**: When querying external services (REST/GraphQL) that return verbose JSON with repetitive keys.
3. **Log & Config Files**: When examining Kubernetes manifests, Docker compose files, or structured telemetry.
4. **Context Window Optimization**: When approaching context limits or wanting to reduce latency and API bill by 50-70%.

## How to Execute

### 1. In Terminal / Shell
```bash
# Compress a file to tabular schema with stats:
tokdown path/to/large_data.json --preset db

# For RAG context prompt generation (Markdown table format):
tokdown path/to/data.json --preset rag

# Measure exact token footprint:
tokdown path/to/prompt.txt --count
```

### 2. In Ruby Code (Agent Tools & Scripts)
```ruby
require "tokdown"

# Automatic tabular compression
result = TokDown.compress(raw_data)
prompt = "Analyze the following records:\n#{result}"

# Markdown table output for RAG
markdown_table = TokDown.to_tabular(raw_data, flavor: :pipe)
```

### 3. Via Model Context Protocol (MCP)
If TokDown MCP server is registered:
- Use tool `tokdown_compress` with `{ content: "..." }`
- Use tool `tokdown_count_tokens` with `{ text: "..." }`
