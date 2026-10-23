# frozen_string_literal: true

module TokDown
  # CompressionResult encapsulates all telemetry and metadata from an optimization pass.
  class CompressionResult
    attr_reader :original_text,
                :compressed_text,
                :original_tokens,
                :compressed_tokens,
                :tokens_saved,
                :savings_ratio,
                :original_bytes,
                :compressed_bytes,
                :format,
                :cost_savings

    def initialize(original_text:, compressed_text:, format: :auto)
      @original_text = original_text.to_s
      @compressed_text = compressed_text.to_s
      @format = format.to_sym

      @original_bytes = @original_text.bytesize
      @compressed_bytes = @compressed_text.bytesize

      @original_tokens = Tokenizer.count(@original_text)
      @compressed_tokens = Tokenizer.count(@compressed_text)
      @tokens_saved = [@original_tokens - @compressed_tokens, 0].max

      @savings_ratio = if @original_tokens.positive?
                         ((@tokens_saved.to_f / @original_tokens) * 100.0).round(2)
                       else
                         0.0
                       end

      @cost_savings = Tokenizer.calculate_cost_savings(@tokens_saved)
    end

    # Delegate to compressed string for seamless string interoperability
    def to_s
      @compressed_text
    end

    def inspect
      "#<TokDown::CompressionResult format=#{@format} tokens=#{@original_tokens}->#{@compressed_tokens} (-#{@savings_ratio}%)>"
    end

    # Human-readable summary table
    def summary
      lines = []
      lines << "TokDown Compression Report (#{format.to_s.upcase})"
      lines << "----------------------------------------"
      lines << Kernel.format("Original:   %6d tokens | %7d bytes", original_tokens, original_bytes)
      lines << Kernel.format("Optimized:  %6d tokens | %7d bytes", compressed_tokens, compressed_bytes)
      lines << Kernel.format("Saved:      %6d tokens (%0.1f%%) | %7d bytes", tokens_saved, savings_ratio, original_bytes - compressed_bytes)
      if cost_savings[:gpt_4o]
        lines << "----------------------------------------"
        lines << Kernel.format("Est. Savings (GPT-4o): $%.6f / call ($%.2f / 10k calls)", cost_savings[:gpt_4o], cost_savings[:gpt_4o] * 10_000)
      end
      lines.join("\n")
    end
  end
end
