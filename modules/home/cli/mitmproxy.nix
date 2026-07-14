{pkgs, ...}: let
  captureWeb = pkgs.writeShellApplication {
    name = "capture-web";
    runtimeInputs = [
      pkgs.coreutils
      pkgs.mitmproxy
    ];
    text = ''
      capture_dir="$HOME/captures/web/$(date +%Y-%m-%d_%H-%M-%S)"
      mkdir -p "$capture_dir"
      cd "$capture_dir"

      exec mitmweb \
        --listen-host 127.0.0.1 \
        --listen-port 8080 \
        --web-host 127.0.0.1 \
        --web-port 8081 \
        --set web_open_browser=false \
        --set save_stream_file=session.mitm \
        --set hardump=session.har \
        --set anticache=true
    '';
  };

  harForAi = pkgs.writeShellApplication {
    name = "har-for-ai";
    runtimeInputs = [
      pkgs.coreutils
      pkgs.jq
    ];
    text = ''
      if [ "$#" -ne 1 ]; then
        echo "Usage: har-for-ai <session.har>" >&2
        exit 64
      fi

      input="$1"
      output="api-requests.json"
      tmp_output="$output.tmp"

      if [ ! -f "$input" ]; then
        echo "HAR file not found: $input" >&2
        exit 66
      fi

      if ! command -v jq >/dev/null 2>&1; then
        echo "jq is required but was not found in PATH" >&2
        exit 69
      fi

      if ! jq -c '
        def headers_map:
          reduce (. // [])[] as $h ({}; .[$h.name] = $h.value);

        def textish:
          startswith("text/")
          or contains("json")
          or contains("xml")
          or contains("graphql")
          or contains("x-www-form-urlencoded");

        def static_extension:
          test("\\.(avif|bmp|gif|ico|jpe?g|png|svg|webp|woff2?|ttf|otf|eot|css|js|mjs|map)([?#].*)?$"; "i");

        def static_mime:
          startswith("image/")
          or startswith("font/")
          or . == "text/css"
          or . == "text/javascript"
          or . == "application/javascript"
          or . == "application/x-javascript"
          or . == "application/wasm"
          or . == "application/font-woff"
          or . == "application/font-woff2"
          or . == "image/vnd.microsoft.icon";

        def is_static:
          (.request.url // "") as $url
          | (.response.content.mimeType // "" | ascii_downcase) as $mime
          | ($url | static_extension) or ($mime | static_mime);

        def response_content:
          (.response.content // {}) as $content
          | ($content.mimeType // "" | ascii_downcase) as $mime
          | {
              mimeType: ($content.mimeType // null),
              size: ($content.size // null),
              compression: ($content.compression // null),
              encoding: ($content.encoding // null),
              body: (
                if (($content.encoding // "") == "base64") and (($mime | textish) | not) then
                  null
                else
                  ($content.text // null)
                end
              )
            };

        [
          .log.entries[]?
          | select((is_static | not))
          | {
              startedDateTime,
              request: {
                method: (.request.method // null),
                url: (.request.url // null),
                query: (.request.queryString // []),
                headers: (.request.headers | headers_map),
                body: (.request.postData.text // null)
              },
              response: {
                status: (.response.status // null),
                headers: (.response.headers | headers_map),
                content: response_content
              }
            }
        ]
      ' "$input" > "$tmp_output"; then
        rm -f "$tmp_output"
        echo "Failed to transform HAR" >&2
        exit 65
      fi

      mv "$tmp_output" "$output"
      echo "Wrote $output"
    '';
  };

  sanitizeHar = pkgs.writeShellApplication {
    name = "sanitize-har";
    runtimeInputs = [
      pkgs.coreutils
      pkgs.jq
    ];
    text = ''
      if [ "$#" -ne 1 ]; then
        echo "Usage: sanitize-har <session.har>" >&2
        exit 64
      fi

      input="$1"

      if [ ! -f "$input" ]; then
        echo "HAR file not found: $input" >&2
        exit 66
      fi

      if ! command -v jq >/dev/null 2>&1; then
        echo "jq is required but was not found in PATH" >&2
        exit 69
      fi

      input_dir="$(dirname "$input")"
      input_base="$(basename "$input")"
      output="$input_dir/''${input_base%.har}.sanitized.har"
      tmp_output="$output.tmp"

      if ! jq '
        def redact_auth_headers:
          if type == "array" then
            map(
              if ((.name // "") | ascii_downcase) == "authorization" then
                .value = "<REDACTED>"
              else
                .
              end
            )
          else
            .
          end;

        def redact_auth_fields:
          walk(
            if type == "object" then
              with_entries(
                if (.key | ascii_downcase) == "authorization" then
                  .value = "<REDACTED>"
                else
                  .
                end
              )
            else
              .
            end
          );

        def redact_json_text($encoding):
          . as $original
          | if type == "string" and (($encoding // "") != "base64") then
              try (fromjson | redact_auth_fields | tojson) catch $original
            else
              .
            end;

        .log.entries |= (
          map(
            .request.headers |= redact_auth_headers
            | .response.headers |= redact_auth_headers
            | if .request.postData.text? then
                .request.postData.text |= redact_json_text(null)
              else
                .
              end
            | if .response.content.text? then
                (.response.content.encoding // null) as $encoding
                | .response.content.text |= redact_json_text($encoding)
              else
                .
              end
          )
        )
      ' "$input" > "$tmp_output"; then
        rm -f "$tmp_output"
        echo "Failed to sanitize HAR" >&2
        exit 65
      fi

      mv "$tmp_output" "$output"
      echo "Wrote $output"
    '';
  };

  captureChromium = pkgs.writeShellApplication {
    name = "capture-chromium";
    runtimeInputs = [
      pkgs.coreutils
      pkgs.google-chrome
    ];
    text = ''
      profile_dir="$HOME/.local/share/api-capture-chromium"
      mkdir -p "$profile_dir"

      exec google-chrome-stable \
        --user-data-dir="$profile_dir" \
        --proxy-server="http://127.0.0.1:8080" \
        "$@"
    '';
  };
in {
  home.packages = [
    pkgs.mitmproxy
    pkgs.jq
    captureWeb
    harForAi
    sanitizeHar
    captureChromium
  ];
}
