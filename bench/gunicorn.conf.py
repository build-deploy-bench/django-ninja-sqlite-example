"""Gunicorn settings for the benchmark: only the marker that the parsers read as the end of app boot."""
import time


def when_ready(server):
    # Gunicorn calls this hook after the listen socket is bound and before it starts the workers.
    print(f"::bench::listening {int(time.time() * 1000)}", flush=True)
