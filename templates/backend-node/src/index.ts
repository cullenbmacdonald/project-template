import express from "express";

const VERSION = process.env.VERSION || "dev";
const COMMIT_HASH = process.env.COMMIT_HASH || "unknown";
const BUILD_TIME = process.env.BUILD_TIME || "unknown";

const app = express();
const port = process.env.PORT || 8080;

app.use(express.json());

app.get("/health", (_req, res) => {
  res.json({
    status: "ok",
    version: VERSION,
    commit_hash: COMMIT_HASH,
    build_time: BUILD_TIME,
  });
});

app.get("/api/v1/hello", (_req, res) => {
  res.json({ message: "Hello, World!" });
});

app.listen(port, () => {
  console.log(`Server starting on port ${port} (version: ${VERSION}, commit: ${COMMIT_HASH})`);
});
