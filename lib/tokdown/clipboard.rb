# frozen_string_literal: true

require "rbconfig"

module TokDown
  # OS-agnostic clipboard helper (Windows, macOS, Linux) with zero external gem dependencies
  class Clipboard
    class << self
      def copy(text)
        return false if text.nil? || text.empty?

        case os_family
        when :windows
          copy_windows(text)
        when :macos
          copy_macos(text)
        when :linux
          copy_linux(text)
        else
          false
        end
      rescue StandardError
        false
      end

      private

      def os_family
        host_os = RbConfig::CONFIG["host_os"]
        case host_os
        when /mswin|msys|mingw|cygwin|bccwin|wince|emc/i
          :windows
        when /darwin|mac os/i
          :macos
        when /linux/i
          :linux
        else
          :unknown
        end
      end

      def copy_windows(text)
        IO.popen("clip", "w") { |pipe| pipe.write(text) }
        true
      end

      def copy_macos(text)
        IO.popen("pbcopy", "w") { |pipe| pipe.write(text) }
        true
      end

      def copy_linux(text)
        cmd = if command_exists?("xclip")
                "xclip -selection clipboard"
              elsif command_exists?("xsel")
                "xsel --clipboard --input"
              elsif command_exists?("wl-copy")
                "wl-copy"
              end
        return false unless cmd

        IO.popen(cmd, "w") { |pipe| pipe.write(text) }
        true
      end

      def command_exists?(cmd)
        ENV["PATH"].to_s.split(File::PATH_SEPARATOR).any? do |dir|
          bin = File.join(dir, cmd)
          File.executable?(bin) && !File.directory?(bin)
        end
      end
    end
  end
end
