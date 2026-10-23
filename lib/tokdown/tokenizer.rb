# frozen_string_literal: true

module TokDown
  # Tokenizer provides fast and accurate token counting heuristics for popular LLMs
  # (OpenAI cl100k_base / o200k_base, Claude, Gemini, DeepSeek).
  # It works in pure Ruby without mandatory C-extensions, with optional native gem integration.
  class Tokenizer
    # Standard pricing in USD per 1,000,000 input tokens (as of late 2024 / 2025)
    RATES = {
      gpt_4o: 2.50,
      claude_3_5_sonnet: 3.00,
      gemini_1_5_pro: 1.25,
      deepseek_v3: 0.14
    }.freeze

    # GPT-style regex pattern for subword/punctuation token splitting
    # Matches words, contraction pieces, numbers, non-word/non-space symbols, and whitespace runs.
    TOKEN_PATTERN = %r{
      (?i:'s|'t|'re|'ve|'m|'ll|'d) |
      [^\r\n\p{L}\p{N}]?+\p{L}+     |
      \p{N}{1,3}                    |
      \ ?[^\s\p{L}\p{N}]++[\r\n]*   |
      \s*[\r\n]+                    |
      \s+(?!\S)                     |
      \s+
    }x

    class << self
      # Estimates token count for a given text
      # @param text [String]
      # @return [Integer] estimated tokens
      def count(text)
        return 0 if text.nil? || text.empty?

        # Try optional native tiktoken_ruby if available
        if defined?(::Tiktoken)
          begin
            @native_encoder ||= ::Tiktoken.get_encoding("o200k_base") rescue ::Tiktoken.get_encoding("cl100k_base")
            return @native_encoder.encode(text).length
          rescue StandardError
            # Fall back to pure Ruby heuristic
          end
        end

        count_heuristic(text)
      end

      # High-performance pure-Ruby BPE heuristic
      # @param text [String]
      # @return [Integer]
      def count_heuristic(text)
        tokens = 0
        text.scan(TOKEN_PATTERN) do |match|
          len = match.length
          if len <= 4
            tokens += 1
          else
            # Longer words or repeated symbols often split into multiple tokens
            tokens += (len / 3.8).ceil
          end
        end
        [tokens, 1].max
      end

      # Calculates estimated dollar savings across popular models
      # @param tokens_saved [Integer]
      # @return [Hash{Symbol => Float}]
      def calculate_cost_savings(tokens_saved)
        return {} if tokens_saved <= 0

        RATES.transform_values do |rate_per_million|
          (tokens_saved.to_f / 1_000_000.0) * rate_per_million
        end
      end
    end
  end
end
