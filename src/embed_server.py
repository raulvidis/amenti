#!/usr/bin/env python3
"""
Amenti Embedding Server — Lightweight HTTP server for local embeddings.

Runs on localhost:9819 (configurable via AMENTI_EMBED_PORT).
Uses all-MiniLM-L6-v2 (80MB, 384 dimensions, ~1ms per embedding after load).

Endpoints:
  POST /embed     — Embed a single text     {"text": "..."}
  POST /embed_batch — Embed multiple texts  {"texts": ["...", "..."]}
  GET  /health    — Health check
  GET  /info      — Model info

Response:
  {"vector": [0.1, 0.2, ...], "dimensions": 384, "model": "all-MiniLM-L6-v2"}
"""

import json
import os
import sys
import signal
from http.server import HTTPServer, BaseHTTPRequestHandler
from sentence_transformers import SentenceTransformer

MODEL_NAME = os.environ.get("AMENTI_EMBED_MODEL", "all-MiniLM-L6-v2")
PORT = int(os.environ.get("AMENTI_EMBED_PORT", "9819"))
HOST = "127.0.0.1"

# Load model once at startup
print(f"Loading model: {MODEL_NAME}...", flush=True)
model = SentenceTransformer(MODEL_NAME)
DIMENSIONS = model.get_sentence_embedding_dimension()
print(f"Model loaded: {MODEL_NAME} ({DIMENSIONS} dimensions)", flush=True)


class EmbedHandler(BaseHTTPRequestHandler):
    def log_message(self, format, *args):
        """Suppress default logging to keep output clean."""
        pass

    def _respond(self, code, data):
        self.send_response(code)
        self.send_header("Content-Type", "application/json")
        self.end_headers()
        self.wfile.write(json.dumps(data).encode())

    def do_GET(self):
        if self.path == "/health":
            self._respond(200, {"status": "ok", "model": MODEL_NAME, "dimensions": DIMENSIONS})
        elif self.path == "/info":
            self._respond(200, {
                "model": MODEL_NAME,
                "dimensions": DIMENSIONS,
                "max_seq_length": model.max_seq_length,
            })
        else:
            self._respond(404, {"error": "not found"})

    def do_POST(self):
        try:
            length = int(self.headers.get("Content-Length", 0))
            body = json.loads(self.rfile.read(length)) if length > 0 else {}
        except (json.JSONDecodeError, ValueError):
            self._respond(400, {"error": "invalid JSON"})
            return

        if self.path == "/embed":
            text = body.get("text", "")
            if not text:
                self._respond(400, {"error": "missing 'text' field"})
                return
            vector = model.encode(text, normalize_embeddings=True).tolist()
            self._respond(200, {
                "vector": vector,
                "dimensions": DIMENSIONS,
                "model": MODEL_NAME,
            })

        elif self.path == "/embed_batch":
            texts = body.get("texts", [])
            if not texts or not isinstance(texts, list):
                self._respond(400, {"error": "missing or invalid 'texts' field"})
                return
            vectors = model.encode(texts, normalize_embeddings=True).tolist()
            self._respond(200, {
                "vectors": vectors,
                "count": len(vectors),
                "dimensions": DIMENSIONS,
                "model": MODEL_NAME,
            })

        else:
            self._respond(404, {"error": "not found"})


def main():
    server = HTTPServer((HOST, PORT), EmbedHandler)
    print(f"Amenti embed server running on {HOST}:{PORT}", flush=True)

    def shutdown(sig, frame):
        print("\nShutting down...", flush=True)
        server.shutdown()
        sys.exit(0)

    signal.signal(signal.SIGINT, shutdown)
    signal.signal(signal.SIGTERM, shutdown)

    try:
        server.serve_forever()
    except KeyboardInterrupt:
        shutdown(None, None)


if __name__ == "__main__":
    main()
