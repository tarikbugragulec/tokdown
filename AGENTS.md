# TokDown AI Agent Protocol (Antigravity)

## 🔻 Mandatory Token Optimization Rule

Whenever preparing context, analyzing data payloads, or injecting structured information into prompts:

1. **Pre-process Data Payloads with TokDown**:
   - If payload is an array of objects or JSON/YAML records with repeated keys, **ALWAYS** compress it using `tokdown` before passing to the model.
   - Run `tokdown [file] --preset db` or use `TokDown.to_tabular(data)` to convert repetitive records into high-density tabular matrix.
   - For RAG / document retrieval context, use `tokdown [file] --preset rag` to produce compact Markdown pipe tables.

2. **Zero Loss of Meaning**:
   - Tabular and TOON representations preserve 100% of data values, relationships, and data types while slashing token usage by 50% to 70%.
   - Always prioritize compressed context to maximize available reasoning window and minimize latency.
