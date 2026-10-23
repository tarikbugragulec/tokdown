# frozen_string_literal: true

require "spec_helper"

RSpec.describe TokDown::Tokenizer do
  describe ".count" do
    it "returns 0 for empty or nil string" do
      expect(described_class.count("")).to eq(0)
      expect(described_class.count(nil)).to eq(0)
    end

    it "estimates tokens for basic sentences" do
      tokens = described_class.count("Hello, world! How are you today?")
      expect(tokens).to be_between(7, 12)
    end

    it "handles numbers, symbols and JSON punctuation" do
      json = '{"id": 101, "name": "TokDown", "active": true}'
      tokens = described_class.count(json)
      expect(tokens).to be > 5
    end
  end

  describe ".calculate_cost_savings" do
    it "computes dollar savings based on model rates" do
      savings = described_class.calculate_cost_savings(1_000_000)
      expect(savings[:gpt_4o]).to eq(2.50)
      expect(savings[:claude_3_5_sonnet]).to eq(3.00)
    end

    it "returns empty hash for non-positive tokens" do
      expect(described_class.calculate_cost_savings(0)).to eq({})
      expect(described_class.calculate_cost_savings(-50)).to eq({})
    end
  end
end
