# frozen_string_literal: true

require "spec_helper"

RSpec.describe TokDown::Compressors::TabularTransformer do
  let(:sample_records) do
    [
      { "id" => 1, "name" => "Alice", "role" => "admin" },
      { "id" => 2, "name" => "Bob", "role" => "editor" },
      { "id" => 3, "name" => "Charlie", "role" => "viewer" }
    ]
  end

  subject { described_class.new }

  describe "#tabular_eligible?" do
    it "identifies uniform arrays of hashes as eligible" do
      expect(subject.tabular_eligible?(sample_records)).to be true
    end

    it "rejects arrays with single element or primitive items" do
      expect(subject.tabular_eligible?([1, 2, 3])).to be false
      expect(subject.tabular_eligible?([{ "a" => 1 }])).to be false
    end
  end

  describe "#to_columnar" do
    it "converts array of hashes to columnar schema" do
      columnar = subject.to_columnar(sample_records)
      expect(columnar["_cols"]).to eq(%w[id name role])
      expect(columnar["_rows"].length).to eq(3)
      expect(columnar["_rows"].first).to eq([1, "Alice", "admin"])
    end
  end

  describe "#to_pipe_table" do
    it "renders clean markdown table" do
      table = subject.to_pipe_table(sample_records)
      expect(table).to include("|id|name|role|")
      expect(table).to include("|1|Alice|admin|")
      expect(table).to include("|2|Bob|editor|")
    end
  end

  describe "#to_tsv_table" do
    it "renders tab-separated rows" do
      tsv = subject.to_tsv_table(sample_records)
      expect(tsv).to include("id\tname\trole")
      expect(tsv).to include("1\tAlice\tadmin")
    end
  end

  describe "#compress" do
    it "reduces JSON size for uniform array of objects" do
      json_input = JSON.generate(sample_records)
      compressed = subject.compress(json_input)
      parsed = JSON.parse(compressed)
      expect(parsed).to have_key("_cols")
      expect(parsed).to have_key("_rows")
    end
  end
end
