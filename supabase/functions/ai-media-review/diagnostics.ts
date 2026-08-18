const FORBIDDEN_KEYS = new Set([
  "path",
  "localPath",
  "videoPath",
  "bytes",
  "base64",
  "content_base64",
  "content",
  "prompt",
  "messages",
  "apiKey",
  "api_key",
  "token",
  "secret",
  "authorization",
  "email",
]);

export type DiagnosticFields = Record<string, string | number | boolean | null>;

export function sanitizeFields(
  fields: Record<string, unknown>,
): DiagnosticFields {
  const safe: DiagnosticFields = {};
  for (const [key, value] of Object.entries(fields)) {
    if (FORBIDDEN_KEYS.has(key)) continue;
    if (value == null) {
      safe[key] = null;
      continue;
    }
    if (typeof value === "number" || typeof value === "boolean") {
      safe[key] = value;
      continue;
    }
    if (typeof value === "string") {
      if (
        value.startsWith("/") ||
        value.startsWith("file:") ||
        value.startsWith("content:") ||
        value.includes("\\")
      ) {
        safe[key] = "redacted_path";
        continue;
      }
      if (value.length > 80) {
        safe[key] = `${value.slice(0, 40)}…`;
        continue;
      }
      safe[key] = value;
    }
  }
  return safe;
}

export function logStage(
  requestId: string,
  stage: string,
  fields: Record<string, unknown> = {},
): void {
  const safe = sanitizeFields(fields);
  const parts = [`ironsight.ai_review`, `request_id=${requestId}`, `stage=${stage}`];
  for (const [key, value] of Object.entries(safe)) {
    parts.push(`${key}=${value}`);
  }
  console.log(parts.join(" "));
}

export function newRequestId(): string {
  return crypto.randomUUID();
}
