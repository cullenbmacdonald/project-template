import os
from fastapi import FastAPI

VERSION = os.getenv("VERSION", "dev")
COMMIT_HASH = os.getenv("COMMIT_HASH", "unknown")
BUILD_TIME = os.getenv("BUILD_TIME", "unknown")

app = FastAPI()


@app.get("/health")
def health():
    return {
        "status": "ok",
        "version": VERSION,
        "commit_hash": COMMIT_HASH,
        "build_time": BUILD_TIME,
    }


@app.get("/api/v1/hello")
def hello():
    return {"message": "Hello, World!"}
