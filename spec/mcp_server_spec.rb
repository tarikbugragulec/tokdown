# frozen_string_literal: true

require "spec_helper"
require "tokdown/mcp_server"

RSpec.describe TokDown::MCPServer do
  subject { described_class.new }

  describe "#handle_request" do
    it "responds to initialize with protocol and serverInfo" do
      req = { "jsonrpc" => "2.0", "id" => 1, "method" => "initialize", "params" => {} }
      res = subject.send(:handle_request, req)

      expect(res[:id]).to eq(1)
      expect(res[:result][:serverInfo][:name]).to eq("tokdown")
      expect(res[:result][:capabilities]).to have_key(:tools)
    end

    it "lists available tools" do
      req = { "jsonrpc" => "2.0", "id" => 2, "method" => "tools/list", "params" => {} }
      res = subject.send(:handle_request, req)

      tools = res[:result][:tools]
      tool_names = tools.map { |t| t[:name] }
      expect(tool_names).to include("tokdown_compress")
      expect(tool_names).to include("tokdown_count_tokens")
    end

    it "executes tokdown_compress tool successfully" do
      payload = '[{"id":1,"name":"Alice"},{"id":2,"name":"Bob"}]'
      req = {
        "jsonrpc" => "2.0",
        "id" => 3,
        "method" => "tools/call",
        "params" => {
          "name" => "tokdown_compress",
          "arguments" => {
            "content" => payload,
            "format" => "tabular",
            "flavor" => "pipe"
          }
        }
      }

      res = subject.send(:handle_request, req)
      expect(res[:id]).to eq(3)
      content = res[:result][:content].first[:text]
      expect(content).to include("|id|name|")
      expect(content).to include("|1|Alice|")
    end

    it "executes tokdown_count_tokens tool successfully" do
      req = {
        "jsonrpc" => "2.0",
        "id" => 4,
        "method" => "tools/call",
        "params" => {
          "name" => "tokdown_count_tokens",
          "arguments" => {
            "text" => "Calculate tokens for this prompt"
          }
        }
      }

      res = subject.send(:handle_request, req)
      content = res[:result][:content].first[:text]
      expect(content).to include("Estimated Tokens:")
    end
  end
end
