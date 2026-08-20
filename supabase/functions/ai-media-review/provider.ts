// Swappable server-side AI provider for media review.
// Flutter never calls this. Credentials stay in Edge Function secrets.

import { logStage } from "./diagnostics.ts";
import {
  classifyProviderHttpStatus,
  ProviderError,
} from "./errors.ts";
import { REVIEW_JSON_SCHEMA, SYSTEM_PROMPT } from "./schema.ts";
import { validateReviewResult } from "./validate.ts";

export interface ProviderImage {
  id: string;
  role: string;
  label: string;
  slot?: string;
  frame_index?: number;
  mime_type: string;
  content_base64: string;
}

export interface ProviderRequest {
  requestId: string;
  companyId: string;
  inspectionId: string;
  images: ProviderImage[];
}

export interface ProviderAdapter {
  analyze(request: ProviderRequest): Promise<unknown>;
}

/** Shorter than the Edge Function wall-clock so we can return a stable timeout. */
export const PROVIDER_TIMEOUT_MS = 25_000;

export function createProviderAdapter(): ProviderAdapter {
  const apiKey = Deno.env.get("AI_API_KEY")?.trim() ?? "";
  if (!apiKey) {
    throw new ProviderUnconfiguredError();
  }
  const baseUrl = (Deno.env.get("AI_PROVIDER_BASE_URL") ??
    "https://api.openai.com/v1").replace(/\/+$/, "");
  const model = Deno.env.get("AI_MODEL")?.trim() || "gpt-4o-mini";
  return new OpenAiCompatibleProvider(baseUrl, apiKey, model);
}

export class ProviderUnconfiguredError extends Error {
  constructor() {
    super("AI provider is not configured");
    this.name = "ProviderUnconfiguredError";
  }
}

export function parseChatCompletion(body: unknown): unknown {
  if (body == null || typeof body !== "object") {
    throw new ProviderError("provider_empty", 502);
  }
  const map = body as {
    choices?: Array<{
      finish_reason?: string | null;
      message?: {
        content?: string | null;
        refusal?: string | null;
      };
    }>;
  };
  const choice = map.choices?.[0];
  if (!choice) {
    throw new ProviderError("provider_empty", 502);
  }
  if (choice.message?.refusal) {
    throw new ProviderError("provider_refusal", 502);
  }
  const reason = choice.finish_reason ?? "stop";
  if (reason === "content_filter") {
    throw new ProviderError("provider_refusal", 502);
  }
  if (reason === "length") {
    throw new ProviderError("provider_incomplete", 502);
  }
  const text = choice.message?.content;
  if (text == null || String(text).trim() === "") {
    throw new ProviderError("provider_empty", 502);
  }
  try {
    return JSON.parse(String(text));
  } catch {
    throw new ProviderError("provider_invalid_json", 422);
  }
}

class OpenAiCompatibleProvider implements ProviderAdapter {
  constructor(
    private readonly baseUrl: string,
    private readonly apiKey: string,
    private readonly model: string,
  ) {}

  async analyze(request: ProviderRequest): Promise<unknown> {
    const content: unknown[] = [
      {
        type: "text",
        text:
          "Analyze only the attached still images. Frame-based video review. " +
          "Walkaround stills are video frames, not photos. " +
          "Return zero suggestions if nothing reliable is visible.",
      },
    ];
    for (const image of request.images) {
      const mime = image.mime_type || "image/jpeg";
      content.push({
        type: "image_url",
        image_url: {
          url: `data:${mime};base64,${image.content_base64}`,
        },
      });
    }

    const controller = new AbortController();
    const timer = setTimeout(() => controller.abort(), PROVIDER_TIMEOUT_MS);
    const started = Date.now();
    logStage(request.requestId, "provider_started", {
      model: this.model,
      timeout_ms: PROVIDER_TIMEOUT_MS,
    });

    let response: Response;
    try {
      response = await fetch(`${this.baseUrl}/chat/completions`, {
        method: "POST",
        headers: {
          Authorization: `Bearer ${this.apiKey}`,
          "Content-Type": "application/json",
        },
        signal: controller.signal,
        body: JSON.stringify({
          model: this.model,
          temperature: 0,
          max_tokens: 4000,
          response_format: {
            type: "json_schema",
            json_schema: {
              name: "ai_media_review_result",
              strict: true,
              schema: REVIEW_JSON_SCHEMA,
            },
          },
          messages: [
            { role: "system", content: SYSTEM_PROMPT },
            { role: "user", content },
          ],
        }),
      });
    } catch (error) {
      clearTimeout(timer);
      if (error instanceof DOMException && error.name === "AbortError") {
        logStage(request.requestId, "provider_timeout", {
          latency_ms: Date.now() - started,
        });
        throw new ProviderError("provider_timeout", 504);
      }
      logStage(request.requestId, "provider_http_failure", {
        latency_ms: Date.now() - started,
      });
      throw new ProviderError("provider_http", 502);
    }
    clearTimeout(timer);

    const latencyMs = Date.now() - started;
    logStage(request.requestId, "provider_http_status", {
      http_status: response.status,
      latency_ms: latencyMs,
    });

    if (!response.ok) {
      throw classifyProviderHttpStatus(response.status);
    }

    let body: unknown;
    try {
      body = await response.json();
    } catch {
      throw new ProviderError("provider_invalid_json", 422);
    }

    const finishReason =
      (body as { choices?: Array<{ finish_reason?: string }> })
        .choices?.[0]?.finish_reason ?? "unknown";
    logStage(request.requestId, "provider_finish_reason", {
      finish_reason: finishReason,
      latency_ms: latencyMs,
    });

    const parsed = parseChatCompletion(body);
    const validated = validateReviewResult(parsed);
    logStage(request.requestId, "normalized_success", {
      suggestion_count: validated.suggestions.length,
    });
    return validated;
  }
}
