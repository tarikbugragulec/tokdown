# frozen_string_literal: true

module TokDown
  class Error < StandardError; end
  class ParseError < Error; end
  class UnsupportedFormatError < Error; end
  class CompressionError < Error; end
end
