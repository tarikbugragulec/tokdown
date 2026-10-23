# frozen_string_literal: true

module TokDown
  module Compressors
    # Abstract base class for all TokDown compressors
    class Base
      attr_reader :options

      def initialize(options = {})
        @options = default_options.merge(options)
      end

      # Default options template to be overridden by subclasses
      def default_options
        {
          level: :balanced, # :lossless, :balanced, :aggressive
          prune_nulls: false,
          prune_empty: false,
          detect_tables: true
        }
      end

      # Compresses input text or data structure
      # @param input [String, Object]
      # @return [String]
      def compress(input)
        raise NotImplementedError, "#{self.class}#compress must be implemented"
      end

      protected

      # Deep clone a ruby data structure
      def deep_dup(obj)
        Marshal.load(Marshal.dump(obj))
      rescue StandardError
        obj
      end

      # Recursively prunes nulls and empty values if requested
      def prune_data(obj, prune_nulls: false, prune_empty: false)
        case obj
        when Hash
          result = {}
          obj.each do |k, v|
            next if prune_nulls && v.nil?
            next if prune_empty && ((v.is_a?(Hash) || v.is_a?(Array) || v.is_a?(String)) && v.empty?)

            cleaned_v = prune_data(v, prune_nulls: prune_nulls, prune_empty: prune_empty)
            next if prune_empty && ((cleaned_v.is_a?(Hash) || cleaned_v.is_a?(Array) || cleaned_v.is_a?(String)) && cleaned_v.empty?)

            result[k] = cleaned_v
          end
          result
        when Array
          result = obj.map { |item| prune_data(item, prune_nulls: prune_nulls, prune_empty: prune_empty) }
          result.reject!(&:nil?) if prune_nulls
          result.reject! { |v| (v.is_a?(Hash) || v.is_a?(Array) || v.is_a?(String)) && v.empty? } if prune_empty
          result
        else
          obj
        end
      end
    end
  end
end
