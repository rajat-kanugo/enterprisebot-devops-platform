import json
import os
import tempfile
import threading
import unittest
from http.server import ThreadingHTTPServer
from pathlib import Path
from urllib.request import urlopen
from unittest.mock import patch

import app


class ConfigEndpointTests(unittest.TestCase):
    def test_reads_environment_when_config_map_files_are_absent(self):
        with tempfile.TemporaryDirectory() as config_dir:
            with patch.object(app, "CONFIG_DIR", Path(config_dir)):
                environment = {"APP_NAME": "env-app", "VERSION": "2.0"}
                with patch.dict(os.environ, environment):
                    self.assertEqual(app.config_value("APP_NAME"), "env-app")
                    self.assertEqual(app.config_value("VERSION"), "2.0")

    def test_get_root_observes_config_map_updates(self):
        with tempfile.TemporaryDirectory() as config_dir:
            config_path = Path(config_dir)
            (config_path / "APP_NAME").write_text("first-app", encoding="utf-8")
            (config_path / "VERSION").write_text("1.0", encoding="utf-8")
            with patch.object(app, "CONFIG_DIR", config_path):
                environment = {"APP_NAME": "env-app", "VERSION": "env-version"}
                with patch.dict(os.environ, environment):
                    server = ThreadingHTTPServer(("127.0.0.1", 0), app.Handler)
                    thread = threading.Thread(target=server.serve_forever)
                    thread.start()
                    try:
                        url = "http://127.0.0.1:{}/".format(server.server_port)
                        with urlopen(url) as response:
                            first = json.load(response)
                        self.assertEqual(first["app"], "first-app")
                        self.assertEqual(first["version"], "1.0")

                        (config_path / "APP_NAME").write_text("updated-app", encoding="utf-8")
                        (config_path / "VERSION").write_text("2.0", encoding="utf-8")
                        with urlopen(url) as response:
                            updated = json.load(response)
                        self.assertEqual(updated["app"], "updated-app")
                        self.assertEqual(updated["version"], "2.0")
                    finally:
                        server.shutdown()
                        server.server_close()
                        thread.join()


if __name__ == "__main__":
    unittest.main()
