# frozen_string_literal: true

require "json"
require_relative "../tokdown"

module TokDown
  # MCP (Model Context Protocol) Server for TokDown
  # Allows AI agents (Antigravity, Claude Desktop, Cursor, etc.) to natively invoke TokDown
  # to minimize context window consumption on-the-fly.
  class MCPServer
    PROTOCOL_VERSION = "2024-11-05"

    def self.start
      new.run
    end

    def run
      $stdin.sync = true
      $stdout.sync = true
      $stderr.puts "[TokDown MCP] Server started on stdio"

      $stdin.each_line do |line|
        line = line.strip
        next if line.empty?

        request = JSON.parse(line) rescue nil
        next unless request.is_a?(Hash)

        response = handle_request(request)
        if response
          $stdout.puts JSON.generate(response)
          $stdout.flush
        end
      end
    rescue Interrupt, Errno::EPIPE
      $stderr.puts "[TokDown MCP] Server stopped"
    end

    private

    def handle_request(req)
      id = req["id"]
      method = req["method"]
      params = req["params"] || {}

      case method
      when "initialize"
        {
          jsonrpc: "2.0",
          id: id,
          result: {
            protocolVersion: PROTOCOL_VERSION,
            capabilities: { tools: {} },
            serverInfo: {
              name: "tokdown",
              version: TokDown::VERSION
            }
          }
        }
      when "notifications/initialized"
        nil # Notification, no response required
      when "tools/list"
        {
          jsonrpc: "2.0",
          id: id,
          result: {
            tools: tool_definitions
          }
        }
      when "tools/call"
        result = call_tool(params["name"], params["arguments"] || {})
        {
          jsonrpc: "2.0",
          id: id,
          result: result
        }
      else
        {
          jsonrpc: "2.0",
          id: id,
          error: { code: -32601, message: "Method not found: #{method}" }
        }
      end
    rescue StandardError => e
      {
        jsonrpc: "2.0",
        id: id,
        error: { code: -32000, message: e.message }
      }
    end

    def tool_definitions
      [
        {
          name: "tokdown_compress",
          description: "Compresses JSON, YAML, or structured data payloads to cut LLM token usage by 40-70% using tabular transformation or TOON notation.",
          inputSchema: {
            type: "object",
            properties: {
              content: {
                type: "string",
                description: "The JSON, YAML, or structured string to compress"
              },
              format: {
                type: "string",
                enum: %w[auto json yaml tabular toon],
                description: "Target compression format (default: auto)"
              },
              flavor: {
                type: "string",
                enum: %w[compact_json pipe tsv],
                description: "Tabular flavor: 'compact_json' (columnar JSON), 'pipe' (Markdown table), 'tsv' (tab-separated)"
              },
              level: {
                type: "string",
                enum: %w[balanced aggressive lossless],
                description: "Compression aggressiveness (default: balanced)"
              }
            },
            required: ["content"]
          }
        },
        {
          name: "tokdown_count_tokens",
          description: "Accurately estimates token count and dollar cost across GPT-4o, Claude 3.5, and Gemini for any prompt or context string.",
          inputSchema: {
            type: "object",
            properties: {
              text: {
                type: "string",
                description: "The text or prompt to analyze"
              }
            },
            required: ["text"]
          }
        }
      ]
    end

    def call_tool(name, args)
      case name
      when "tokdown_compress"
        content = args["content"].to_s
        format = (args["format"] || "auto").to_sym
        flavor = (args["flavor"] || "compact_json").to_sym
        level = (args["level"] || "balanced").to_sym

        result = TokDown.compress(content, format: format, flavor: flavor, level: level)

        {
          content: [
            {
              type: "text",
              text: result.compressed_text
            },
            {
              type: "text",
              text: "\n<!-- Telemetry: #{result.original_tokens} -> #{result.compressed_tokens} tokens (Saved #{result.savings_ratio}%) -->"
            }
          ]
        }
      when "tokdown_count_tokens"
        text = args["text"].to_s
        tokens = TokDown.count_tokens(text)
        costs = TokDown::Tokenizer.calculate_cost_savings(tokens)

        summary_text = [
          "Estimated Tokens: #{tokens}",
          "Input Cost (GPT-4o): $#{Kernel.format('%.6f', costs[:gpt_4o] || 0)}",
          "Input Cost (Claude 3.5 Sonnet): $#{Kernel.format('%.6f', costs[:claude_3_5_sonnet] || 0)}"
        ].join("\n")

        {
          content: [
            {
              type: "text",
              text: summary_text
            }
          ]
        }
      else
        raise "Unknown tool: #{name}"
      end
    end
  end
end
