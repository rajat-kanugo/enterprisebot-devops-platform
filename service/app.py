import json
import os
import socket
from http.server import BaseHTTPRequestHandler, ThreadingHTTPServer
from pathlib import Path

CONFIG_DIR = Path("/etc/enterprisebot-config")


def config_value(name):
    config_path = CONFIG_DIR / name
    if config_path.is_file():
        return config_path.read_text(encoding="utf-8").rstrip("\r\n")
    return os.environ.get(name, "")


class Handler(BaseHTTPRequestHandler):
    def send_json(self, status, payload):
        body = json.dumps(payload, separators=(",", ":")).encode("utf-8")
        self.send_response(status)
        self.send_header("Content-Type", "application/json")
        self.send_header("Content-Length", str(len(body)))
        self.end_headers()
        self.wfile.write(body)

    def do_GET(self):
        if self.path == "/healthz":
            self.send_json(200, {"status": "ok"})
            return

        if self.path == "/":
            self.send_json(
                200,
                {
                    "app": config_value("APP_NAME"),
                    "version": config_value("VERSION"),
                    "pod": socket.gethostname(),
                },
            )
            return

        self.send_json(404, {"error": "not found"})

    def log_message(self, format, *args):
        print(
            "%s - - [%s] %s"
            % (self.address_string(), self.log_date_time_string(), format % args),
            flush=True,
        )


if __name__ == "__main__":
    port = int(os.environ.get("PORT", "8080"))
    ThreadingHTTPServer(("0.0.0.0", port), Handler).serve_forever()
