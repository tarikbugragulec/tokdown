# frozen_string_literal: true

require "spec_helper"

RSpec.describe TokDown::Compressors::JsonCompressor do
  let(:complex_json) do
    <<~JSON
      {
        "status": "ok",
        "data": [
          { "id": 1, "sku": "A1", "price": 19.99 },
          { "id": 2, "sku": "B2", "price": 29.99 },
          { "id": 3, "sku": "C3", "price": 39.99 }
        ],
        "meta": {
          "total": 3,
          "null_value": null
        }
      }
    JSON
  end

  it "compresses JSON and converts nested tabular data" do
    compressor = described_class.new(target_format: :auto)
    compressed = compressor.compress(complex_json)
    parsed = JSON.parse(compressed)
    expect(parsed["data"]).to have_key("_cols")
    expect(parsed["data"]).to have_key("_rows")
  end

  it "strips null values when requested" do
    compressor = described_class.new(prune_nulls: true)
    compressed = compressor.compress(complex_json)
    expect(compressed).not_to include("null_value")
  end

  it "converts to TOON when target_format is :toon" do
    compressor = described_class.new(target_format: :toon)
    compressed = compressor.compress(complex_json)
    expect(compressed).to start_with("{status:ok,data:{_cols:")
  end
end
