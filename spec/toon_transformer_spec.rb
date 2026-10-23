# frozen_string_literal: true

require "spec_helper"

RSpec.describe TokDown::Compressors::ToonTransformer do
  subject { described_class.new }

  describe "#encode" do
    it "encodes identifiers without quotes" do
      input = { "name" => "TokDown", "active" => true }
      output = subject.encode(input)
      expect(output).to eq("{name:TokDown,active:true}")
    end

    it "quotes strings that contain punctuation or spaces" do
      input = { "description" => "A fast & lightweight token reducer" }
      output = subject.encode(input)
      expect(output).to include('description:"A fast & lightweight token reducer"')
    end

    it "handles nested structures and arrays" do
      input = { "user" => { "id" => 1, "tags" => %w[ai ruby] } }
      output = subject.encode(input)
      expect(output).to eq("{user:{id:1,tags:[ai,ruby]}}")
    end

    it "supports aggressive abbreviations" do
      aggressive = described_class.new(level: :aggressive)
      input = { "enabled" => true, "disabled" => false, "empty" => nil }
      output = aggressive.encode(input)
      expect(output).to eq("{enabled:t,disabled:f,empty:~}")
    end
  end

  describe "#compress" do
    it "prunes nulls and empty fields in aggressive mode" do
      aggressive = described_class.new(level: :aggressive)
      input = { "id" => 1, "missing" => nil, "tags" => [] }
      output = aggressive.compress(input)
      expect(output).to eq("{id:1}")
    end
  end
end
