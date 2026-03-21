const path = require("node:path");

const DEFAULT_PORT = 9080;
const REQUEST_TIMEOUT_MS = 12000;
const DEFAULT_MANIFEST_URL =
  "https://myapk.sgp1.cdn.digitaloceanspaces.com/manifests/update.json";
const DEFAULT_STATS_FILE = path.join(
  __dirname,
  "..",
  "data",
  "download-counts.json",
);

function resolvePort() {
  const parsed = Number.parseInt(process.env.PORT ?? "", 10);
  return Number.isNaN(parsed) ? DEFAULT_PORT : parsed;
}

module.exports = {
  port: resolvePort(),
  requestTimeoutMs: REQUEST_TIMEOUT_MS,
  updateManifestUrl: process.env.UPDATE_MANIFEST_URL || DEFAULT_MANIFEST_URL,
  statsFile: process.env.STATS_FILE || DEFAULT_STATS_FILE,
};
