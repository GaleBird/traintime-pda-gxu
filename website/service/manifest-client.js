const config = require("./config");

const DEFAULT_SUMMARY = "官网、下载直链和版本说明保持同一来源。";
const CHANGELOG_PREFIX = /^full changelog:/i;
const DOWNLOAD_MAP = [
  { id: "arm64-v8a", label: "Android arm64", keyword: "arm64-v8a" },
  { id: "armeabi-v7a", label: "Android 32-bit", keyword: "armeabi-v7a" },
  { id: "x86_64", label: "Android x86_64", keyword: "x86_64" },
];

async function fetchManifest() {
  const response = await fetch(config.updateManifestUrl, {
    signal: AbortSignal.timeout(config.requestTimeoutMs),
    headers: { Accept: "application/json" },
  });
  if (!response.ok) {
    throw new Error(`manifest returned ${response.status}`);
  }
  return response.json();
}

function normalizeVersionTag(rawTag) {
  const match = /(\d+(?:\.\d+)*)(?:\+(\d+))?/.exec(rawTag ?? "");
  if (!match) {
    throw new Error(`unsupported tag ${rawTag}`);
  }
  return match[2] ? `${match[1]}+${match[2]}` : match[1];
}

function parseReleaseNotes(body) {
  return (body ?? "")
    .split("\n")
    .map(normalizeReleaseLine)
    .filter(Boolean);
}

function normalizeReleaseLine(line) {
  const cleaned = String(line ?? "")
    .trim()
    .replace(/^#+\s*/, "")
    .replace(/^(?:[-*]\s*)+/, "")
    .replace(/^\d+\.\s*/, "")
    .replace(/\[([^\]]+)\]\((https?:\/\/[^)]+)\)/gi, "$1")
    .replace(/https?:\/\/\S+/gi, "")
    .replace(/\*\*/g, "")
    .replace(/\s{2,}/g, " ")
    .trim();
  if (!cleaned || cleaned === "---" || CHANGELOG_PREFIX.test(cleaned)) {
    return null;
  }
  return cleaned;
}

function normalizeDownloads(assets) {
  const source = Array.isArray(assets) ? assets : [];
  return DOWNLOAD_MAP.map((item) => {
    const asset = source.find(
      (entry) =>
        String(entry?.name ?? "").toLowerCase().includes(item.keyword),
    );
    if (!asset) {
      return null;
    }
    return {
      id: item.id,
      label: item.label,
      href: `/download/${item.id}`,
      url: String(asset.browser_download_url ?? ""),
    };
  }).filter(Boolean);
}

function buildUpdateView(manifest) {
  const notes = parseReleaseNotes(manifest.body);
  return {
    version: normalizeVersionTag(manifest.tag_name),
    releaseUrl: String(manifest.html_url ?? ""),
    releaseLabel: String(manifest.tag_name ?? "GitHub Release"),
    notes,
    summary: notes[0] || DEFAULT_SUMMARY,
    downloads: normalizeDownloads(manifest.assets),
  };
}

function resolveDownloadTarget(update, id) {
  if (id === "github") {
    return update.releaseUrl
      ? { id: "github", url: update.releaseUrl }
      : null;
  }
  if (id === "android") {
    return (
      update.downloads.find((item) => item.id === "arm64-v8a") ||
      update.downloads[0] ||
      null
    );
  }
  return update.downloads.find((item) => item.id === id) || null;
}

module.exports = {
  buildUpdateView,
  fetchManifest,
  resolveDownloadTarget,
};
