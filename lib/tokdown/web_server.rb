# frozen_string_literal: true

require "socket"
require "json"
require "uri"
require_relative "../tokdown"

module TokDown
  # Zero-dependency, lightweight local web server providing an interactive UI playground.
  # Can be launched via `tokdown ui` or `tokdown web`.
  class WebServer
    DEFAULT_PORT = 7890

    def self.start(port: DEFAULT_PORT)
      new(port: port).run
    end

    def initialize(port: DEFAULT_PORT)
      @port = port
    end

    def run
      server = TCPServer.new("127.0.0.1", @port)
      url = "http://localhost:#{@port}"

      puts ""
      puts "\e[1;36m┌────────────────────────────────────────────────────────┐\e[0m"
      puts "\e[1;36m│          ✨ TokDown Interactive Web Playground         │\e[0m"
      puts "\e[1;36m├────────────────────────────────────────────────────────┤\e[0m"
      puts "\e[1;36m│ Local Server: \e[1;32m#{url}\e[1;36m                           │\e[0m"
      puts "\e[1;36m│ Press Ctrl+C anytime to stop.                          │\e[0m"
      puts "\e[1;36m└────────────────────────────────────────────────────────┘\e[0m"
      puts ""

      open_browser(url)

      loop do
        client = server.accept
        handle_connection(client)
      rescue StandardError => e
        warn "Server error: #{e.message}"
      end
    ensure
      server&.close
    end

    private

    def open_browser(url)
      Thread.new do
        sleep 0.4
        case RbConfig::CONFIG["host_os"]
        when /mswin|msys|mingw|cygwin/i
          system("start #{url}")
        when /darwin/i
          system("open #{url}")
        when /linux/i
          system("xdg-open #{url} > /dev/null 2>&1")
        end
      end
    end

    def handle_connection(client)
      request_line = client.gets
      return client.close unless request_line

      method, path, = request_line.split(" ")
      headers = {}
      while (line = client.gets) && line.strip != ""
        key, value = line.split(":", 2)
        headers[key.downcase.strip] = value&.strip
      end

      if method == "POST" && path == "/api/compress"
        content_length = headers["content-length"].to_i
        body = client.read(content_length)
        respond_api_compress(client, body)
      elsif method == "GET" && (path == "/" || path == "/index.html")
        respond_html(client, render_html)
      else
        respond_not_found(client)
      end
    ensure
      client.close
    end

    def respond_api_compress(client, body)
      data = JSON.parse(body) rescue {}
      text = data["text"] || ""
      format = (data["format"] || "auto").to_sym
      level = (data["level"] || "balanced").to_sym
      flavor = (data["flavor"] || "compact_json").to_sym

      result = TokDown.compress(text, format: format, level: level, flavor: flavor)

      response_payload = JSON.generate({
        compressed: result.compressed_text,
        original_tokens: result.original_tokens,
        compressed_tokens: result.compressed_tokens,
        tokens_saved: result.tokens_saved,
        savings_ratio: result.savings_ratio,
        cost_savings: result.cost_savings
      })

      client.puts "HTTP/1.1 200 OK\r\nContent-Type: application/json\r\nAccess-Control-Allow-Origin: *\r\nContent-Length: #{response_payload.bytesize}\r\n\r\n#{response_payload}"
    rescue StandardError => e
      err = JSON.generate({ error: e.message })
      client.puts "HTTP/1.1 400 Bad Request\r\nContent-Type: application/json\r\nContent-Length: #{err.bytesize}\r\n\r\n#{err}"
    end

    def respond_html(client, html)
      client.puts "HTTP/1.1 200 OK\r\nContent-Type: text/html; charset=utf-8\r\nContent-Length: #{html.bytesize}\r\n\r\n#{html}"
    end

    def respond_not_found(client)
      client.puts "HTTP/1.1 404 Not Found\r\nContent-Length: 0\r\n\r\n"
    end

    def render_html
      <<~HTML
        <!DOCTYPE html>
        <html lang="en">
        <head>
          <meta charset="UTF-8">
          <meta name="viewport" content="width=device-width, initial-scale=1.0">
          <title>TokDown Playground | LLM Token Optimizer</title>
          <link rel="preconnect" href="https://fonts.googleapis.com">
          <link rel="preconnect" href="https://fonts.gstatic.com" crossorigin>
          <link href="https://fonts.googleapis.com/css2?family=JetBrains+Mono:wght@400;500;700&family=Plus+Jakarta+Sans:wght@400;500;600;700&display=swap" rel="stylesheet">
          <style>
            :root {
              --bg: #0b0f19;
              --card: #111827;
              --border: #1f2937;
              --accent: #3b82f6;
              --accent-hover: #2563eb;
              --success: #10b981;
              --text: #f3f4f6;
              --text-muted: #9ca3af;
              --editor-bg: #0d1117;
            }
            * { box-sizing: border-box; margin: 0; padding: 0; }
            body {
              font-family: 'Plus Jakarta Sans', sans-serif;
              background: var(--bg);
              color: var(--text);
              min-height: 100vh;
              display: flex;
              flex-direction: column;
            }
            header {
              display: flex;
              align-items: center;
              justify-content: space-between;
              padding: 1rem 2rem;
              background: rgba(17, 24, 39, 0.8);
              backdrop-filter: blur(12px);
              border-bottom: 1px solid var(--border);
            }
            .brand {
              display: flex;
              align-items: center;
              gap: 0.75rem;
              font-weight: 700;
              font-size: 1.25rem;
              color: #fff;
            }
            .brand span { color: var(--accent); }
            .badge {
              font-size: 0.75rem;
              background: rgba(59, 130, 246, 0.15);
              color: var(--accent);
              padding: 0.2rem 0.5rem;
              border-radius: 999px;
              border: 1px solid rgba(59, 130, 246, 0.3);
            }
            .actions-top { display: flex; gap: 0.75rem; }
            button {
              font-family: inherit;
              cursor: pointer;
              font-weight: 500;
              padding: 0.5rem 1rem;
              border-radius: 8px;
              border: 1px solid var(--border);
              background: var(--card);
              color: var(--text);
              transition: all 0.2s ease;
              font-size: 0.875rem;
            }
            button:hover { background: #1f2937; border-color: #374151; }
            button.primary {
              background: var(--accent);
              border-color: var(--accent);
              color: #fff;
            }
            button.primary:hover { background: var(--accent-hover); }
            .toolbar {
              display: flex;
              flex-wrap: wrap;
              gap: 1.5rem;
              padding: 0.85rem 2rem;
              background: var(--card);
              border-bottom: 1px solid var(--border);
              align-items: center;
            }
            .control-group {
              display: flex;
              align-items: center;
              gap: 0.5rem;
              font-size: 0.875rem;
              color: var(--text-muted);
            }
            select {
              background: var(--bg);
              color: var(--text);
              border: 1px solid var(--border);
              padding: 0.4rem 0.8rem;
              border-radius: 6px;
              font-family: inherit;
              font-size: 0.875rem;
              outline: none;
            }
            .stats-bar {
              display: flex;
              align-items: center;
              gap: 2rem;
              margin-left: auto;
            }
            .stat-pill {
              display: flex;
              flex-direction: column;
            }
            .stat-pill .label { font-size: 0.7rem; color: var(--text-muted); text-transform: uppercase; }
            .stat-pill .value { font-size: 1.1rem; font-weight: 700; color: #fff; font-family: 'JetBrains Mono', monospace; }
            .stat-pill .value.savings { color: var(--success); }
            main {
              flex: 1;
              display: grid;
              grid-template-columns: 1fr 1fr;
              gap: 1px;
              background: var(--border);
            }
            .panel {
              background: var(--bg);
              display: flex;
              flex-direction: column;
              overflow: hidden;
            }
            .panel-header {
              padding: 0.75rem 1.25rem;
              background: var(--card);
              border-bottom: 1px solid var(--border);
              display: flex;
              justify-content: space-between;
              align-items: center;
              font-size: 0.875rem;
              font-weight: 600;
            }
            textarea {
              flex: 1;
              width: 100%;
              background: var(--editor-bg);
              border: none;
              color: #e6edf3;
              font-family: 'JetBrains Mono', monospace;
              font-size: 0.9rem;
              line-height: 1.5;
              padding: 1.25rem;
              resize: none;
              outline: none;
            }
            #copyNotice {
              display: none;
              color: var(--success);
              font-size: 0.8rem;
              font-weight: 600;
            }
          </style>
        </head>
        <body>
          <header>
            <div class="brand">
              🔻 TokDown <span>Playground</span>
              <span class="badge">v#{TokDown::VERSION}</span>
            </div>
            <div class="actions-top">
              <button onclick="clearAll()">Clear</button>
              <button class="primary" onclick="compressLive()">⚡ Optimize Tokens</button>
            </div>
          </header>

          <div class="toolbar">
            <div class="control-group">
              <label for="formatSelect">Format:</label>
              <select id="formatSelect" onchange="compressLive()">
                <option value="auto">Auto (Detect)</option>
                <option value="tabular">Tabular (Columnar)</option>
                <option value="toon">TOON (Token-Optimized Object Notation)</option>
                <option value="json">Standard Minified JSON</option>
              </select>
            </div>

            <div class="control-group">
              <label for="flavorSelect">Flavor:</label>
              <select id="flavorSelect" onchange="compressLive()">
                <option value="compact_json">Columnar JSON</option>
                <option value="pipe">Markdown / Pipe Table</option>
                <option value="tsv">TSV (Tab-Separated)</option>
              </select>
            </div>

            <div class="control-group">
              <label for="levelSelect">Aggressiveness:</label>
              <select id="levelSelect" onchange="compressLive()">
                <option value="balanced">Balanced</option>
                <option value="aggressive">Aggressive (Prune Nulls + Abbr)</option>
                <option value="lossless">Lossless</option>
              </select>
            </div>

            <div class="stats-bar">
              <div class="stat-pill">
                <span class="label">Original</span>
                <span class="value" id="origTokens">0</span>
              </div>
              <div class="stat-pill">
                <span class="label">Optimized</span>
                <span class="value" id="optTokens">0</span>
              </div>
              <div class="stat-pill">
                <span class="label">Tokens Saved</span>
                <span class="value savings" id="savedRatio">0%</span>
              </div>
            </div>
          </div>

          <main>
            <div class="panel">
              <div class="panel-header">
                <span>Input Payload (JSON / YAML)</span>
                <span id="inputCharCount" style="color:var(--text-muted); font-size:0.8rem;">0 chars</span>
              </div>
              <textarea id="inputText" placeholder="Paste your raw JSON or YAML here..."></textarea>
            </div>

            <div class="panel">
              <div class="panel-header">
                <span>Optimized Context (LLM-Ready)</span>
                <div style="display:flex; align-items:center; gap:0.75rem;">
                  <span id="copyNotice">✓ Copied!</span>
                  <button onclick="copyOutput()" style="padding:0.25rem 0.6rem; font-size:0.75rem;">📋 Copy</button>
                </div>
              </div>
              <textarea id="outputText" readonly placeholder="Optimized token-reduced text will appear here..."></textarea>
            </div>
          </main>

            function clearAll() {
              document.getElementById('inputText').value = '';
              document.getElementById('outputText').value = '';
              updateStats(0, 0, 0);
            }

            async function compressLive() {
              const text = document.getElementById('inputText').value;
              if (!text.trim()) {
                document.getElementById('outputText').value = '';
                updateStats(0, 0, 0);
                return;
              }

              document.getElementById('inputCharCount').innerText = `${text.length} chars`;

              const format = document.getElementById('formatSelect').value;
              const flavor = document.getElementById('flavorSelect').value;
              const level = document.getElementById('levelSelect').value;

              try {
                const res = await fetch('/api/compress', {
                  method: 'POST',
                  headers: { 'Content-Type': 'application/json' },
                  body: JSON.stringify({ text, format, flavor, level })
                });
                const data = await res.json();
                if (data.compressed) {
                  document.getElementById('outputText').value = data.compressed;
                  updateStats(data.original_tokens, data.compressed_tokens, data.savings_ratio);
                }
              } catch (err) {
                console.error(err);
              }
            }

            function updateStats(orig, opt, ratio) {
              document.getElementById('origTokens').innerText = orig.toLocaleString();
              document.getElementById('optTokens').innerText = opt.toLocaleString();
              document.getElementById('savedRatio').innerText = `-${ratio}%`;
            }

            function copyOutput() {
              const output = document.getElementById('outputText').value;
              if (!output) return;
              navigator.clipboard.writeText(output);
              const notice = document.getElementById('copyNotice');
              notice.style.display = 'inline';
              setTimeout(() => { notice.style.display = 'none'; }, 2000);
            }

            document.getElementById('inputText').addEventListener('input', () => {
              clearTimeout(window.typeTimer);
              window.typeTimer = setTimeout(compressLive, 250);
            });
          </script>
        </body>
        </html>
      HTML
    end
  end
end
