const { createVerify } = require("node:crypto");

const HTTPS_PROTOCOL = "https:";
const SIGNATURE_ALGORITHM = "RSA-SHA256";

function assertAllowedRemoteUrl(rawUrl, allowedHosts, label) {
  const value = String(rawUrl ?? "").trim();
  if (!value) {
    throw new Error(`${label} is missing`);
  }
  const url = new URL(value);
  if (url.protocol !== HTTPS_PROTOCOL) {
    throw new Error(`${label} must use https`);
  }
  if (!allowedHosts.includes(url.hostname)) {
    throw new Error(`${label} host is not allowed: ${url.hostname}`);
  }
  return url.toString();
}

function verifyManifestSignature(manifest, config) {
  const baseStatus = {
    enabled: Boolean(config.manifestPublicKeyPem),
    required: config.requireManifestSignature,
    verified: false,
    status: "disabled",
    keyId: config.manifestSignatureKeyId || "",
    message: "服务端未启用清单验签。",
  };

  if (!config.manifestPublicKeyPem) {
    return baseStatus;
  }

  const signature = manifest?.signature;
  if (!signature || typeof signature !== "object") {
    return finalizeSignatureStatus(
      { ...baseStatus, status: "missing_signature" },
      config,
      "公钥已配置，但线上清单缺少签名。",
    );
  }

  const algorithm = String(signature.algorithm ?? "").trim();
  const keyId = String(signature.key_id ?? "").trim();
  const statusWithKey = { ...baseStatus, keyId: keyId || baseStatus.keyId };

  if (algorithm !== SIGNATURE_ALGORITHM) {
    return finalizeSignatureStatus(
      { ...statusWithKey, status: "unsupported_algorithm" },
      config,
      `不支持的清单签名算法：${algorithm || "空值"}。`,
    );
  }

  if (config.manifestSignatureKeyId && keyId !== config.manifestSignatureKeyId) {
    return finalizeSignatureStatus(
      { ...statusWithKey, status: "key_id_mismatch" },
      config,
      "清单签名 key_id 与当前服务配置不一致。",
    );
  }

  try {
    const verifier = createVerify(SIGNATURE_ALGORITHM);
    verifier.update(canonicalizeUnsignedManifest(manifest), "utf8");
    verifier.end();

    const signatureValue = Buffer.from(String(signature.value ?? ""), "base64");
    const isVerified = verifier.verify(config.manifestPublicKeyPem, signatureValue);
    if (!isVerified) {
      return finalizeSignatureStatus(
        { ...statusWithKey, status: "invalid_signature" },
        config,
        "清单签名与当前公钥不匹配。",
      );
    }
  } catch (error) {
    return finalizeSignatureStatus(
      { ...statusWithKey, status: "verification_error" },
      config,
      `清单验签执行失败：${error.message}`,
    );
  }

  return {
    ...statusWithKey,
    verified: true,
    status: "verified",
    message: "清单已通过服务端验签。",
  };
}

function finalizeSignatureStatus(status, config, message) {
  const result = { ...status, message };
  if (config.requireManifestSignature) {
    throw new Error(message);
  }
  return result;
}

function canonicalizeUnsignedManifest(manifest) {
  return canonicalizeSignedJson(stripSignature(manifest));
}

function canonicalizeSignedJson(value) {
  if (Array.isArray(value)) {
    return `[${value.map(canonicalizeSignedJson).join(",")}]`;
  }
  if (value && typeof value === "object") {
    const keys = Object.keys(value).sort();
    const body = keys
      .map((key) => `${JSON.stringify(key)}:${canonicalizeSignedJson(value[key])}`)
      .join(",");
    return `{${body}}`;
  }
  return JSON.stringify(value);
}

function stripSignature(manifest) {
  const source = manifest && typeof manifest === "object" ? manifest : {};
  const { signature, ...unsignedManifest } = source;
  return unsignedManifest;
}

module.exports = {
  assertAllowedRemoteUrl,
  verifyManifestSignature,
  canonicalizeSignedJson,
  canonicalizeUnsignedManifest,
};
