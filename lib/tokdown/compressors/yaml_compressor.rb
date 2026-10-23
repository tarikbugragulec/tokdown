# frozen_string_literal: true

require "yaml"
require "date"
require "json"
require_relative "base"
require_relative "tabular_transformer"
require_relative "toon_transformer"

module TokDown
  module Compressors
    # YamlCompressor processes YAML payloads.
    # Because YAML indentation and multi-line structures consume excessive tokens in BPE tokenizers,
    # YamlCompressor can condense YAML directly or convert it into compact JSON/TOON for maximum token efficiency.
    class YamlCompressor < Base
      def default_options
        super.merge(
          target_format: :auto # :auto, :yaml_dense, :json_dense, :tabular, :toon
        )
      end

      # Compresses YAML input
      # @param input [String, Hash, Array]
      # @return [String]
      def compress(input)
        data = parse(input)

        if @options[:level] == :aggressive
          data = prune_data(data, prune_nulls: true, prune_empty: true)
        elsif @options[:prune_nulls] || @options[:prune_empty]
          data = prune_data(data, prune_nulls: @options[:prune_nulls], prune_empty: @options[:prune_empty])
        end

        case @options[:target_format]
        when :toon
          ToonTransformer.new(@options).compress(data)
        when :tabular
          TabularTransformer.new(@options).compress(data)
        when :json_dense
          JSON.generate(data)
        when :yaml_dense
          to_dense_yaml(data)
        else # :auto
          # For LLMs, dense JSON or Tabular representation of YAML is significantly cheaper than indented YAML!
          if @options[:detect_tables] && contains_tabular_data?(data)
            TabularTransformer.new(@options).compress(data)
          else
            to_dense_yaml(data)
          end
        end
      end

      # Compresses YAML into dense format by removing comments and collapsing empty lines
      def to_dense_yaml(data)
        raw_yaml = YAML.dump(data)
        # Strip header '---' and trailing dots if present, trim trailing whitespace per line
        lines = raw_yaml.lines.map(&:rstrip)
        lines.reject! { |l| l.strip.empty? || l.strip.start_with?("#") }
        lines.shift if lines.first == "---"
        lines.pop if lines.last == "..."
        lines.join("\n")
      end

      private

      def parse(input)
        if input.is_a?(String)
          YAML.safe_load(input, permitted_classes: [Date, Time, Symbol])
        else
          deep_dup(input)
        end
      rescue StandardError => e
        raise ParseError, "Invalid YAML input: #{e.message}"
      end

      def contains_tabular_data?(data)
        tabular_helper = TabularTransformer.new(@options)
        if data.is_a?(Array) && tabular_helper.tabular_eligible?(data)
          return true
        elsif data.is_a?(Hash)
          data.each_value do |val|
            return true if val.is_a?(Array) && tabular_helper.tabular_eligible?(val)
          end
        end
        false
      end
    end
  end
end
