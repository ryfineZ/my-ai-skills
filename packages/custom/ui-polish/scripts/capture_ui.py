#!/usr/bin/env python3
from __future__ import annotations

import argparse
import contextlib
import http.server
import socket
import socketserver
import subprocess
import sys
import threading
import time
from pathlib import Path
from urllib.parse import quote


CHROME_CANDIDATES = [
    "/Applications/Google Chrome.app/Contents/MacOS/Google Chrome",
    "/Applications/Microsoft Edge.app/Contents/MacOS/Microsoft Edge",
]


def find_browser() -> str:
    for candidate in CHROME_CANDIDATES:
        if Path(candidate).exists():
            return candidate
    raise FileNotFoundError("未找到可用浏览器，请安装 Google Chrome 或 Microsoft Edge。")


class QuietHandler(http.server.SimpleHTTPRequestHandler):
    def log_message(self, format: str, *args) -> None:
        return


@contextlib.contextmanager
def serve_directory(directory: Path, port: int):
    if port == 0:
        with socket.socket(socket.AF_INET, socket.SOCK_STREAM) as sock:
            sock.bind(("127.0.0.1", 0))
            port = sock.getsockname()[1]
    handler = lambda *args, **kwargs: QuietHandler(*args, directory=str(directory), **kwargs)
    with socketserver.TCPServer(("127.0.0.1", port), handler) as httpd:
        thread = threading.Thread(target=httpd.serve_forever, daemon=True)
        thread.start()
        try:
            yield port
        finally:
            httpd.shutdown()
            thread.join(timeout=1)


def capture(url: str, output: Path, width: int, height: int, delay_ms: int) -> None:
    browser = find_browser()
    output.parent.mkdir(parents=True, exist_ok=True)
    cmd = [
        browser,
        "--headless=new",
        "--disable-gpu",
        "--hide-scrollbars",
        f"--window-size={width},{height}",
        f"--screenshot={output}",
        url,
    ]
    subprocess.run(cmd, check=True)
    if not output.exists():
        raise FileNotFoundError(f"截图命令执行后未找到输出文件: {output}")
    if delay_ms:
        time.sleep(delay_ms / 1000)


def parse_args() -> argparse.Namespace:
    parser = argparse.ArgumentParser(description="Capture a local UI screenshot with a real browser.")
    parser.add_argument("--url", help="Remote or local URL to capture.")
    parser.add_argument("--file", help="Local html file to capture.")
    parser.add_argument("--out", required=True, help="Output png path.")
    parser.add_argument("--width", type=int, default=1440)
    parser.add_argument("--height", type=int, default=1080)
    parser.add_argument("--port", type=int, default=0)
    parser.add_argument("--delay-ms", type=int, default=300)
    return parser.parse_args()


def main() -> int:
    args = parse_args()
    output = Path(args.out).expanduser().resolve()

    if bool(args.url) == bool(args.file):
        raise SystemExit("必须二选一：传 --url 或 --file。")

    if args.url:
        capture(args.url, output, args.width, args.height, args.delay_ms)
        print(output)
        return 0

    html_file = Path(args.file).expanduser().resolve()
    if not html_file.exists():
        raise SystemExit(f"文件不存在: {html_file}")

    with serve_directory(html_file.parent, args.port) as port:
        url = f"http://127.0.0.1:{port}/{quote(html_file.name)}"
        time.sleep(0.4)
        capture(url, output, args.width, args.height, args.delay_ms)

    print(output)
    return 0


if __name__ == "__main__":
    sys.exit(main())
