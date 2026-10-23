# frozen_string_literal: true

require "optparse"
require_relative "../tokdown"
require_relative "clipboard"
require_relative "web_server"
require_relative "mcp_server"

module TokDown
  class CLI
    # ANSI color helpers
    module Color
      RESET  = "\e[0m"
      BOLD   = "\e[1m"
      DIM    = "\e[2m"
      RED    = "\e[31m"
      GREEN  = "\e[32m"
      YELLOW = "\e[33m"
      BLUE   = "\e[34m"
      CYAN   = "\e[36m"
      GRAY   = "\e[90m"

      def self.enabled?
        !ENV["NO_COLOR"] && $stderr.tty?
      end

      def self.paint(text, code)
        enabled? ? "#{code}#{text}#{RESET}" : text
      end
    end

    def self.start(args = ARGV)
      new(args).run
    end

    def initialize(args)
      @args = args.dup
      @options = {
        format: :auto,
        level: :balanced,
        flavor: :compact_json,
        stats: false,
        quiet: false,
        count_only: false,
        output_file: nil,
        prune_nulls: false,
        prune_empty: false,
        copy: false
      }
    end

    def run
      # Handle subcommands like 'ui', 'web', or 'mcp'
      if @args.first =~ /\A(ui|web|playground)\z/i
        WebServer.start
        return
      elsif @args.first =~ /\Amcp\z/i
        MCPServer.start
        return
      end

      parse_options!

      content = read_input
      if content.nil? || content.strip.empty?
        # User-friendly interactive onboarding when executed without arguments on a TTY
        if $stdin.tty?
          run_interactive_wizard
          return
        else
          $stderr.puts Color.paint("Error: No input provided. Provide a file path or pipe content via STDIN.", Color::RED)
          $stderr.puts Color.paint("Run 'tokdown --help' or 'tokdown ui' for interactive mode.", Color::GRAY)
          exit 1
        end
      end

      if @options[:count_only]
        tokens = TokDown.count_tokens(content)
        bytes = content.bytesize
        if @options[:quiet]
          puts tokens
        else
          puts Color.paint("Tokens: #{tokens} | Bytes: #{bytes}", Color::CYAN)
        end
        return
      end

      result = TokDown.compress(
        content,
        format: @options[:format],
        level: @options[:level],
        flavor: @options[:flavor],
        prune_nulls: @options[:prune_nulls],
        prune_empty: @options[:prune_empty]
      )

      # Copy to clipboard if requested
      if @options[:copy]
        if Clipboard.copy(result.compressed_text)
          $stderr.puts Color.paint("📋 Copied optimized text to clipboard! (Saved #{result.savings_ratio}%)", Color::GREEN) unless @options[:quiet]
        else
          $stderr.puts Color.paint("⚠️ Could not access OS clipboard.", Color::YELLOW) unless @options[:quiet]
        end
      end

      # Write output
      if @options[:output_file]
        File.write(@options[:output_file], result.compressed_text)
        $stderr.puts Color.paint("✓ Written compressed output to #{@options[:output_file]}", Color::GREEN) unless @options[:quiet]
      else
        puts result.compressed_text
      end

      # Print statistics if requested
      print_stats_card(result) if @options[:stats] && !@options[:quiet]
    rescue TokDown::Error => e
      $stderr.puts Color.paint("TokDown Error: #{e.message}", Color::RED)
      exit 1
    rescue StandardError => e
      $stderr.puts Color.paint("Unexpected Error: #{e.message}", Color::RED)
      $stderr.puts e.backtrace if ENV["DEBUG"]
      exit 1
    end

    private

    def parse_options!
      parser = OptionParser.new do |opts|
        opts.banner = Color.paint("Usage: tokdown [options] [file]  OR  tokdown [ui|mcp]", Color::BOLD)
        opts.separator ""
        opts.separator Color.paint("Commands:", Color::CYAN)
        opts.separator "    ui, web                          Launch the interactive browser playground"
        opts.separator "    mcp                              Start Model Context Protocol (MCP) server for AI agents"
        opts.separator ""
        opts.separator Color.paint("Options:", Color::CYAN)

        opts.on("-f", "--format FORMAT", %i[auto json yaml tabular toon],
                "Target format: auto, json, yaml, tabular, toon (default: auto)") do |f|
          @options[:format] = f
        end

        opts.on("-l", "--level LEVEL", %i[lossless balanced aggressive],
                "Optimization level: lossless, balanced, aggressive (default: balanced)") do |lvl|
          @options[:level] = lvl
        end

        opts.on("--flavor FLAVOR", %i[compact_json pipe tsv],
                "Tabular flavor: compact_json, pipe, tsv (default: compact_json)") do |flv|
          @options[:flavor] = flv
        end

        opts.on("--preset PRESET", %i[rag db toon],
                "Presets: 'rag' (pipe tables for RAG), 'db' (compact json), 'toon' (dense notation)") do |p|
          case p
          when :rag
            @options[:format] = :tabular
            @options[:flavor] = :pipe
          when :db
            @options[:format] = :tabular
            @options[:flavor] = :compact_json
          when :toon
            @options[:format] = :toon
          end
        end

        opts.on("-c", "--copy", "Automatically copy compressed output directly to clipboard") do
          @options[:copy] = true
        end

        opts.on("-o", "--output FILE", "Write output to specified file path") do |out|
          @options[:output_file] = out
        end

        opts.on("-s", "--stats", "Display detailed token reduction telemetry to stderr") do
          @options[:stats] = true
        end

        opts.on("--count", "Only count tokens for the input without compressing") do
          @options[:count_only] = true
        end

        opts.on("--prune-nulls", "Strip null/nil keys and values") do
          @options[:prune_nulls] = true
        end

        opts.on("--prune-empty", "Strip empty arrays and objects") do
          @options[:prune_empty] = true
        end

        opts.on("-q", "--quiet", "Quiet mode: print only compressed output, silence logs") do
          @options[:quiet] = true
        end

        opts.on("-v", "--version", "Show TokDown version") do
          puts "TokDown version #{TokDown::VERSION}"
          exit 0
        end

        opts.on("-h", "--help", "Show this help message") do
          print_banner
          puts opts
          exit 0
        end
      end

      parser.parse!(@args)
    end

    def read_input
      if @args.any?
        filepath = @args.first
        unless File.exist?(filepath)
          $stderr.puts Color.paint("Error: File not found: #{filepath}", Color::RED)
          exit 1
        end
        File.read(filepath)
      elsif !$stdin.tty?
        $stdin.read
      else
        nil
      end
    end

    def run_interactive_wizard
      print_banner
      puts Color.paint("Welcome! Choose an option to get started:", Color::CYAN)
      puts "  [1] 🌐 Launch Interactive Web Playground in browser"
      puts "  [2] ✍️  Paste text or JSON interactively"
      puts "  [3] 📖 View help & command-line options"
      puts "  [q] Exit"
      puts ""
      print Color.paint("Enter choice (1-3): ", Color::BOLD)
      choice = $stdin.gets&.strip

      case choice
      when "1"
        WebServer.start
      when "2"
        puts Color.paint("\nPaste your JSON or text (end with Ctrl+D or Ctrl+Z on Windows):", Color::CYAN)
        input = $stdin.read
        if input && !input.strip.empty?
          result = TokDown.compress(input)
          puts "\n" + Color.paint("Optimized Output:", Color::GREEN)
          puts result.compressed_text
          print_stats_card(result)
        end
      when "3"
        parse_options!
        exit 0
      else
        puts "Exiting. Have a great day!"
        exit 0
      end
    end

    def print_banner
      banner = <<~BANNER
        #{Color.paint('  _____     _    ____                     ', Color::CYAN)}
        #{Color.paint(' |_   _|___| | _|  _ \\  _____      ___ __  ', Color::CYAN)}
        #{Color.paint('   | | / _ \\ |/ / | | |/ _ \\ \\ /\\ / / \'_ \\ ', Color::BLUE)}
        #{Color.paint('   | || (_) |   <| |_| | (_) \\ V  V /| | | |', Color::BLUE)}
        #{Color.paint('   |_| \\___/|_|\\_\\____/ \\___/ \\_/\\_/ |_| |_|', Color::CYAN)}
        #{Color.paint("   Advanced Token Reducer for LLMs v#{TokDown::VERSION}", Color::DIM)}
      BANNER
      puts banner
      puts ""
    end

    def print_stats_card(result)
      $stderr.puts ""
      $stderr.puts Color.paint("┌────────────────────────────────────────────────────────┐", Color::CYAN)
      $stderr.puts Color.paint("│              TOKDOWN COMPRESSION REPORT                │", Color::CYAN)
      $stderr.puts Color.paint("├──────────────────────┬─────────────┬─────────────┬─────┤", Color::CYAN)
      $stderr.puts Color.paint("│ Metric               │ Original    │ Optimized   │ Diff│", Color::CYAN)
      $stderr.puts Color.paint("├──────────────────────┼─────────────┼─────────────┼─────┤", Color::CYAN)

      diff_token = "-#{result.savings_ratio}%"
      token_line = format(
        "│ Estimated Tokens     │ %11s │ %11s │ %3s │",
        number_with_delimiter(result.original_tokens),
        number_with_delimiter(result.compressed_tokens),
        Color.paint(format("%-4s", diff_token), Color::GREEN)
      )
      $stderr.puts token_line

      bytes_saved_pct = result.original_bytes.positive? ? ((result.original_bytes - result.compressed_bytes).to_f / result.original_bytes * 100).round(1) : 0
      bytes_diff = "-#{bytes_saved_pct}%"
      bytes_line = format(
        "│ Bytes (UTF-8)        │ %9s B │ %9s B │ %3s │",
        number_with_delimiter(result.original_bytes),
        number_with_delimiter(result.compressed_bytes),
        Color.paint(format("%-4s", bytes_diff), Color::GREEN)
      )
      $stderr.puts bytes_line

      fmt_line = format("│ Target Format        │ %11s │ %11s │     │", result.format.to_s.upcase, "COMPACT")
      $stderr.puts fmt_line

      $stderr.puts Color.paint("└──────────────────────┴─────────────┴─────────────┴─────┘", Color::CYAN)

      if result.cost_savings[:gpt_4o] && result.cost_savings[:gpt_4o].positive?
        saved_per_10k = result.cost_savings[:gpt_4o] * 10_000
        $stderr.puts Color.paint("✨ Est. GPT-4o Savings: $#{format('%.4f', result.cost_savings[:gpt_4o])} / request ($#{format('%.2f', saved_per_10k)} / 10k requests)", Color::YELLOW)
      end
      $stderr.puts ""
    end

    def number_with_delimiter(number)
      number.to_s.reverse.gsub(/(\d{3})(?=\d)/, '\\1,').reverse
    end
  end
end
