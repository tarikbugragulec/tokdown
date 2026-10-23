# frozen_string_literal: true

require "spec_helper"

RSpec.describe TokDown::Compressors::YamlCompressor do
  let(:yaml_content) do
    <<~YAML
      # Production Configuration
      app:
        name: TokDown
        version: 1.0.0
        # Database pool settings
        database:
          host: localhost
          port: 5432
      users:
        - id: 1
          role: admin
        - id: 2
          role: editor
    YAML
  end

  it "cleans comments and generates dense YAML" do
    compressor = described_class.new(target_format: :yaml_dense)
    compressed = compressor.compress(yaml_content)
    expect(compressed).not_to include("# Production")
    expect(compressed).to include("name: TokDown")
  end

  it "auto-converts nested arrays of objects to tabular format" do
    compressor = described_class.new(target_format: :auto)
    compressed = compressor.compress(yaml_content)
    expect(compressed).to include("_cols")
  end
end
