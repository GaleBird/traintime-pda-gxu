const http = require("node:http");

const config = require("./config");
const {
  buildUpdateView,
  fetchManifest,
  resolveDownloadTarget,
} = require("./manifest-client");
const { StatsStore } = require("./stats-store");

const statsStore = new StatsStore(config.statsFile);

function logSecurityMode() {
  if (config.manifestPublicKeyPem) {
    console.log(
      `manifest signature verification is configured (required=${config.requireManifestSignature})`,
    );
    return;
  }
  console.warn(
    "manifest signature verification is disabled; set MANIFEST_PUBLIC_KEY_PEM to enable it",
  );
}

function sendJson(res, statusCode, payload) {
  res.writeHead(statusCode, {
    "Content-Type": "application/json; charset=utf-8",
    "Cache-Control": "no-store",
  });
  res.end(`${JSON.stringify(payload)}\n`);
}

function sendRedirect(res, location) {
  res.writeHead(302, {
    Location: location,
    "Cache-Control": "no-store",
  });
  res.end();
}

function sendError(res, statusCode, message) {
  sendJson(res, statusCode, { error: message });
}

async function loadUpdateView() {
  const { manifest, signature } = await fetchManifest();
  return buildUpdateView(manifest, signature);
}

async function handleUpdate(res) {
  try {
    sendJson(res, 200, await loadUpdateView());
  } catch (error) {
    sendError(res, 502, error.message);
  }
}

async function handleStats(res) {
  try {
    sendJson(res, 200, await statsStore.snapshot());
  } catch (error) {
    sendError(res, 500, error.message);
  }
}

async function handleDownload(res, downloadId, shouldCount) {
  try {
    const update = await loadUpdateView();
    const target = resolveDownloadTarget(update, downloadId);
    if (!target) {
      sendError(res, 404, "download target not found");
      return;
    }
    if (shouldCount) {
      await statsStore.increment(downloadId, target.id, "site");
    }
    sendRedirect(res, target.url);
  } catch (error) {
    sendError(res, 502, error.message);
  }
}

function routeDownload(pathname) {
  const prefix = "/download/";
  if (!pathname.startsWith(prefix)) {
    return null;
  }
  return pathname.slice(prefix.length);
}

function routeDownloadCount(pathname) {
  const match = /^\/api\/downloads\/([^/]+)\/count$/.exec(pathname);
  if (!match) {
    return { matched: false, downloadId: null, hasInvalidEncoding: false };
  }
  try {
    return {
      matched: true,
      downloadId: decodeURIComponent(match[1]),
      hasInvalidEncoding: false,
    };
  } catch {
    return { matched: true, downloadId: null, hasInvalidEncoding: true };
  }
}

async function handleDownloadCount(res, downloadId) {
  try {
    const update = await loadUpdateView();
    const target = resolveDownloadTarget(update, downloadId);
    if (!target) {
      sendError(res, 404, "download target not found");
      return;
    }
    await statsStore.increment(downloadId, target.id, "app");
    sendJson(res, 200, { ok: true });
  } catch (error) {
    sendError(res, 500, error.message);
  }
}

function createHandler() {
  return async (req, res) => {
    const url = new URL(req.url ?? "/", "http://127.0.0.1");
    const method = req.method ?? "GET";
    const trackedDownloadRoute = routeDownloadCount(url.pathname);
    if (trackedDownloadRoute.matched) {
      if (trackedDownloadRoute.hasInvalidEncoding) {
        sendError(res, 400, "invalid download target");
        return;
      }
      if (method !== "POST") {
        sendError(res, 405, "method not allowed");
        return;
      }
      await handleDownloadCount(res, trackedDownloadRoute.downloadId);
      return;
    }
    const isHead = method === "HEAD";
    if (method !== "GET" && !isHead) {
      sendError(res, 405, "method not allowed");
      return;
    }
    if (url.pathname === "/healthz") {
      sendJson(res, 200, { status: "ok" });
      return;
    }
    if (url.pathname === "/api/update") {
      await handleUpdate(res);
      return;
    }
    if (url.pathname === "/api/stats") {
      await handleStats(res);
      return;
    }
    const downloadId = routeDownload(url.pathname);
    if (downloadId) {
      await handleDownload(res, downloadId, !isHead);
      return;
    }
    sendError(res, 404, "not found");
  };
}

const server = http.createServer(createHandler());
logSecurityMode();
server.listen(config.port, "127.0.0.1", () => {
  console.log(`gxu.app service listening on http://127.0.0.1:${config.port}`);
});
