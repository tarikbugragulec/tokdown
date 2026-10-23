# frozen_string_literal: true

require "yaml"
require "date"
require "json"

require_relative "tokdown/version"
require_relative "tokdown/error"
require_relative "tokdown/tokenizer"
require_relative "tokdown/compression_result"
require_relative "tokdown/compressors/base"
require_relative "tokdown/compressors/tabular_transformer"
require_relative "tokdown/compressors/toon_transformer"
require_relative "tokdown/compressors/json_compressor"
require_relative "tokdown/compressors/yaml_compressor"

module TokDown
  class << self
    # Compresses input text or data structure to minimize LLM token usage.
    #
    # @param input [String, Hash, Array] The content to optimize
    # @param format [Symbol] Target/source format: :auto, :json, :yaml, :tabular, :toon
    # @param level [Symbol] Optimization aggressiveness: :lossless, :balanced, :aggressive
    # @param options [Hash] Additional options (prune_nulls, prune_empty, flavor, etc.)
    # @return [TokDown::CompressionResult] Result object containing optimized string and token telemetry
    def compress(input, format: :auto, level: :balanced, **options)
      input_str = input.is_a?(String) ? input : JSON.generate(input)
      detected_fmt = format == :auto ? detect_format(input_str) : format.to_sym
      merged_opts = options.merge(level: level)

      compressed_str = case detected_fmt
                       when :json
                         Compressors::JsonCompressor.new(merged_opts).compress(input)
                       when :yaml
                         Compressors::YamlCompressor.new(merged_opts).compress(input)
                       when :tabular
                         Compressors::TabularTransformer.new(merged_opts).compress(input)
                       when :toon
                         Compressors::ToonTransformer.new(merged_opts).compress(input)
                       else
                         # Fallback: try json, else yaml, else return stripped text
                         try_compress_auto(input, merged_opts)
                       end

      CompressionResult.new(
        original_text: input_str,
        compressed_text: compressed_str,
        format: detected_fmt
      )
    end

    # Fast shortcut to convert uniform collections into Tabular representation
    # @param input [String, Hash, Array]
    # @param flavor [Symbol] :compact_json, :pipe, :tsv
    # @return [TokDown::CompressionResult]
    def to_tabular(input, flavor: :compact_json, **options)
      compress(input, format: :tabular, flavor: flavor, **options)
    end

    # Fast shortcut to convert data into Token-Optimized Object Notation (TOON)
    # @param input [String, Hash, Array]
    # @return [TokDown::CompressionResult]
    def to_toon(input, **options)
      compress(input, format: :toon, **options)
    end

    # Calculates estimated token count for any text using LLM BPE heuristics
    # @param text [String]
    # @return [Integer]
    def count_tokens(text)
      Tokenizer.count(text)
    end

    # Detects the underlying format of a string (:json, :yaml, or :text)
    # @param text [String]
    # @return [Symbol]
    def detect_format(text)
      return :text if text.nil? || text.strip.empty?

      trimmed = text.strip
      if (trimmed.start_with?("{") && trimmed.end_with?("}")) ||
         (trimmed.start_with?("[") && trimmed.end_with?("]"))
        begin
          JSON.parse(trimmed)
          return :json
        rescue JSON::ParserError
          # continue to check yaml
        end
      end

      # Check YAML
      if trimmed.start_with?("---") || trimmed.match?(/\A\s*[\w\-"']+\s*:\s*.+/m)
        begin
          parsed = YAML.safe_load(trimmed, permitted_classes: [Date, Time, Symbol])
          return :yaml if parsed.is_a?(Hash) || parsed.is_a?(Array)
        rescue StandardError
          # not yaml
        end
      end

      :text
    end

    private

    def try_compress_auto(input, options)
      if input.is_a?(String)
        begin
          return Compressors::JsonCompressor.new(options).compress(input)
        rescue StandardError
          begin
            return Compressors::YamlCompressor.new(options).compress(input)
          rescue StandardError
            input.strip.gsub(/[ \t]+/, " ")
          end
        end
      else
        Compressors::JsonCompressor.new(options).compress(input)
      end
    end
  end
end
