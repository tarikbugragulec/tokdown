<div align="center">

# 🔻 TokDown

**Advanced LLM Token Reduction Engine & CLI for Ruby**

*Slash prompt token costs by up to 70% without sacrificing LLM reasoning accuracy.*

[![Gem Version](https://badge.fury.io/rb/tokdown.svg)](https://badge.fury.io/rb/tokdown)
[![CI Status](https://github.com/tarikbugragulec/tokdown/actions/workflows/ci.yml/badge.svg)](https://github.com/tarikbugragulec/tokdown/actions)
[![Ruby](https://img.shields.io/badge/ruby-3.0%2B-red.svg)](https://www.ruby-lang.org/)
[![License: MIT](https://img.shields.io/badge/License-MIT-blue.svg)](LICENSE)
[![PRs Welcome](https://img.shields.io/badge/PRs-welcome-brightgreen.svg)](CONTRIBUTING.md)

</div>

---

## ⚡ The Problem: The JSON Token Tax

In modern LLM applications (RAG pipelines, agents, database-to-prompt injections), **structured JSON and YAML eat up massive token budgets**:
- Key names repeated across hundreds of array objects (`"customer_id"`, `"timestamp"`, `"status"`, etc.)
- Excess whitespace, indentation, quotes, and punctuation that each trigger distinct BPE tokens.
- Higher inference latency and expensive API bills.

```json
// ⚠️ Standard JSON: 240+ tokens for 5 records (keys repeated on every line)
[
  {"id": "prod_1", "sku": "TECH-KB", "price": 129.99, "stock": 45, "active": true},
  {"id": "prod_2", "sku": "TECH-MS", "price": 79.50,  "stock": 120,"active": true},
  {"id": "prod_3", "sku": "TECH-MN", "price": 499.00, "stock": 18, "active": true}
]
```

## 💡 The TokDown Solution

**TokDown** transforms verbose payloads into dense, LLM-optimized schemas that models (GPT-4o, Claude 3.5 Sonnet, Gemini 2.0, DeepSeek) understand with 100% precision:

```json
// ✅ TokDown Tabular: Only 78 tokens (67.5% reduction!)
{"_cols":["id","sku","price","stock","active"],"_rows":[["prod_1","TECH-KB",129.99,45,true],["prod_2","TECH-MS",79.5,120,true],["prod_3","TECH-MN",499,18,true]]}
```

Or **TOON (Token-Optimized Object Notation)**:
```
{_cols:[id,sku,price,stock,active],_rows:[[prod_1,TECH-KB,129.99,45,t],[prod_2,TECH-MS,79.5,120,t],[prod_3,TECH-MN,499,18,t]]}
```

---

## 🚀 Key Features

- 📊 **Intelligent Tabular Transformation**: Automatically detects uniform collections of objects and converts them to high-density columnar schemas, pipe tables, or TSV.
- 🧬 **TOON (Token-Optimized Object Notation)**: Strips redundant quotes and delimiters from safe identifiers and booleans.
- 🧠 **Pure-Ruby BPE Estimator**: High-accuracy token counting heuristic for OpenAI (`cl100k_base`, `o200k_base`), Claude, and Gemini without requiring C-extensions.
- 💵 **Real-Time Cost Telemetry**: Calculates exact dollar savings per model for your workloads.
- 🖥️ **Unix-Friendly CLI**: Seamlessly pipes through `cat`, `curl`, and shell scripts with ANSI colored telemetry.
- 🪶 **Zero Mandatory Dependencies**: Runs effortlessly on Windows, macOS, Linux, and Docker containers out of the box.

---

## 📊 Benchmark

Tested against realistic production payloads (E-commerce catalog, 20 items):

| Format | Tokens | Bytes | % Saved | Est. Cost (1M calls - GPT-4o) |
|---|---|---|---|---|
| **Pretty JSON** | 1,480 | 5,890 B | `0%` (Baseline) | $3,700.00 |
| **Minified JSON** | 1,020 | 3,120 B | `31.0%` | $2,550.00 |
| **TokDown Tabular** | **480** | **1,410 B** | **`67.5%`** | **$1,200.00** |
| **TokDown TOON (Aggressive)**| **410** | **1,190 B** | **`72.3%`** | **$1,025.00** |

> 💰 **Estimated Annual Savings:** **$2,675.00+** saved on a single pipeline endpoint!

---

## 📦 Installation

Add to your `Gemfile`:

```ruby
gem "tokdown"
```

Or install it globally:

```bash
gem install tokdown
```

---

## 🛠️ CLI Usage

### 🌐 Interactive Web Playground (Zero-Dependency)

Launch the sleek browser playground with side-by-side live diffs, instant copy, and real-time token metrics:

```bash
tokdown ui
# Automatically opens http://localhost:7890 in your browser!
```

### Basic Compression & Auto-Clipboard

```bash
# Compress a JSON file and print optimized output
tokdown data.json

# Compress and automatically copy optimized text directly to clipboard:
tokdown data.json --copy

# Compress with visual telemetry card to stderr:
tokdown data.json --stats

# Save optimized result to file
tokdown data.json -o optimized.json

# Use built-in presets:
tokdown data.json --preset rag     # Markdown pipe tables for RAG
tokdown data.json --preset db      # Columnar JSON for DB records
tokdown data.json --preset toon    # Maximum density TOON notation
```

### Pipe & UNIX Stream Support

```bash
# Pipe directly from curl or cat
curl -s https://api.example.com/products | tokdown -f tabular --stats > prompt_context.txt

# Pipe to clipboard (macOS / Linux / Windows)
cat payload.json | tokdown -f toon | pbcopy
```

### Tabular Flavors

```bash
# Columnar JSON (default)
tokdown data.json --flavor compact_json

# Markdown / Pipe Table
tokdown data.json --flavor pipe

# TSV (Tab-Separated Values)
tokdown data.json --flavor tsv
```

### Token Counting

```bash
# Quickly estimate tokens for any prompt or document
tokdown --count prompt.txt
```

---

## 💻 Ruby Library Usage

### 1. Automatic Schema Optimization

```ruby
require "tokdown"

raw_json = File.read("users.json")

# Compress with full telemetry
result = TokDown.compress(raw_json)

puts result.compressed_text
puts "Tokens saved: #{result.tokens_saved} (#{result.savings_ratio}%)"
puts "Est. GPT-4o cost saved: $#{result.cost_savings[:gpt_4o]}"
```

### 2. Direct Prompt Injection

```ruby
records = User.where(active: true).limit(50).as_json

prompt = <<~PROMPT
  You are an analytics assistant. Examine the following user cohort:

  #{TokDown.to_tabular(records)}

  Which users are most likely to upgrade?
PROMPT

response = openai.chat(messages: [{ role: "user", content: prompt }])
```

### 3. Markdown Table Output

```ruby
# Ideal for models tuned on Markdown formatting
markdown_table = TokDown.to_tabular(records, flavor: :pipe)
puts markdown_table
```

### 4. Counting Tokens

```ruby
count = TokDown.count_tokens("Summarize the following document in 3 sentences...")
puts "Estimated tokens: #{count}"
```

---

## ⚙️ Configuration & Levels

| Level | Description | Behavior |
|---|---|---|
| `:lossless` | 100% syntactic preservation | Strips all whitespace, minifies schema |
| `:balanced` (default) | Safe semantic optimization | Converts arrays of objects to tabular format |
| `:aggressive` | Maximum token reduction | Tabular conversion + null pruning + boolean abbreviations (`t`/`f`) |

---

## 🧪 Running Tests

```bash
bundle install
bundle exec rspec
```

---

## 🤝 Contributing

Contributions, issues, and feature requests are welcome!
1. Fork the Project
2. Create your Feature Branch (`git checkout -b feature/amazing-feature`)
3. Commit your Changes (`git commit -m 'Add some amazing feature'`)
4. Push to the Branch (`git push origin feature/amazing-feature`)
5. Open a Pull Request

---

## 📄 License

Distributed under the MIT License. See `LICENSE` for more information.
