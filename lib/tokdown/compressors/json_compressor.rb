# frozen_string_literal: true

require "json"
require_relative "base"
require_relative "tabular_transformer"
require_relative "toon_transformer"

module TokDown
  module Compressors
    # JsonCompressor optimizes JSON payloads for LLM context windows.
    # Offers lossless minification, tabular transformation, and TOON encoding.
    class JsonCompressor < Base
      def default_options
        super.merge(
          target_format: :auto # :auto, :minified, :tabular, :toon
        )
      end

      # Compresses JSON string or Ruby Hash/Array
      # @param input [String, Hash, Array]
      # @return [String]
      def compress(input)
        data = parse(input)

        # Apply pruning based on level
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
        when :minified
          JSON.generate(data)
        else # :auto
          # In auto mode, if input or part of it is an eligible table, use tabular; otherwise minified
          if @options[:detect_tables] && contains_tabular_data?(data)
            TabularTransformer.new(@options).compress(data)
          else
            JSON.generate(data)
          end
        end
      end

      private

      def parse(input)
        if input.is_a?(String)
          JSON.parse(input)
        else
          deep_dup(input)
        end
      rescue JSON::ParserError => e
        raise ParseError, "Invalid JSON input: #{e.message}"
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
