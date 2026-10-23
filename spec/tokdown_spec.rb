# frozen_string_literal: true

require "spec_helper"

RSpec.describe TokDown do
  describe ".detect_format" do
    it "detects JSON syntax" do
      expect(described_class.detect_format('{"key": "value"}')).to eq(:json)
      expect(described_class.detect_format('[{"id": 1}]')).to eq(:json)
    end

    it "detects YAML syntax" do
      yaml_sample = <<~YAML
        ---
        key: value
        list:
          - one
      YAML
      expect(described_class.detect_format(yaml_sample)).to eq(:yaml)
    end

    it "falls back to text" do
      expect(described_class.detect_format("Just a plain prompt.")).to eq(:text)
    end
  end

  describe ".compress" do
    let(:json_payload) do
      [
        { "id" => 1, "username" => "user_one", "role" => "admin" },
        { "id" => 2, "username" => "user_two", "role" => "user" }
      ]
    end

    it "returns a CompressionResult with token telemetry" do
      result = described_class.compress(JSON.generate(json_payload))
      expect(result).to be_a(TokDown::CompressionResult)
      expect(result.original_tokens).to be > 0
      expect(result.compressed_tokens).to be < result.original_tokens
      expect(result.savings_ratio).to be > 0
    end

    it "converts to TOON shortcut" do
      result = described_class.to_toon(json_payload)
      expect(result.to_s).to include("{_cols:[id,username,role]")
    end

    it "converts to Tabular shortcut" do
      result = described_class.to_tabular(json_payload, flavor: :pipe)
      expect(result.to_s).to include("|id|username|role|")
    end
  end
end
