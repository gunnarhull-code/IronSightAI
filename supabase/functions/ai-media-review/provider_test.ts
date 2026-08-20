import {
  assertEquals,
  assertThrows,
} from "https://deno.land/std@0.224.0/assert/mod.ts";
import { sanitizeFields } from "./diagnostics.ts";
import {
  classifyProviderHttpStatus,
  errorHttpStatus,
  ProviderError,
} from "./errors.ts";
import { parseChatCompletion } from "./provider.ts";
import { REVIEW_JSON_SCHEMA, REVIEW_KIND } from "./schema.ts";
import { validateReviewResult } from "./validate.ts";

function completion(content: unknown, finishReason = "stop") {
  return {
    choices: [
      {
        finish_reason: finishReason,
        message: { content: typeof content === "string" ? content : JSON.stringify(content) },
      },
    ],
  };
}

const validEmpty = {
  review_kind: REVIEW_KIND,
  disclaimer: "AI suggestions only — not verified facts.",
  suggestions: [],
};

const validVideoFrame = {
  review_kind: REVIEW_KIND,
  disclaimer: "AI suggestions only — not verified facts.",
  suggestions: [
    {
      id: "s1",
      kind: "visible_damage_or_wear",
      value: "Scuff on counterweight",
      confidence: "low",
      uncertainty: "Angle is oblique",
      source: {
        type: "video_frame",
        label: "Walkaround video frame 2",
        slot: null,
        frame_index: 1,
      },
    },
  ],
};

Deno.test("structured schema is strict and closed", () => {
  assertEquals(REVIEW_JSON_SCHEMA.additionalProperties, false);
  assertEquals(REVIEW_JSON_SCHEMA.properties.suggestions.items.additionalProperties, false);
  assertEquals(
    REVIEW_JSON_SCHEMA.properties.suggestions.items.properties.source.additionalProperties,
    false,
  );
});

Deno.test("valid video-frame payload is accepted", () => {
  const parsed = validateReviewResult(validVideoFrame);
  assertEquals(parsed.suggestions.length, 1);
  assertEquals(parsed.suggestions[0].source.type, "video_frame");
  assertEquals(parsed.suggestions[0].source.frame_index, 1);
  assertEquals(parsed.suggestions[0].source.slot, null);
});

Deno.test("empty suggestions are valid", () => {
  const parsed = validateReviewResult(validEmpty);
  assertEquals(parsed.suggestions.length, 0);
});

Deno.test("invalid source type is schema-invalid", () => {
  assertThrows(
    () =>
      validateReviewResult({
        ...validEmpty,
        suggestions: [{
          ...validVideoFrame.suggestions[0],
          source: { type: "walkaround", label: "x", slot: null, frame_index: 0 },
        }],
      }),
    ProviderError,
    "provider_schema_invalid",
  );
});

Deno.test("invalid photo slot is schema-invalid", () => {
  assertThrows(
    () =>
      validateReviewResult({
        ...validEmpty,
        suggestions: [{
          id: "s1",
          kind: "manufacturer",
          value: "Cat",
          confidence: "high",
          uncertainty: null,
          source: {
            type: "photo",
            label: "Overview",
            slot: "left_side",
            frame_index: null,
          },
        }],
      }),
    ProviderError,
    "provider_schema_invalid",
  );
});

Deno.test("unknown kind is schema-invalid", () => {
  assertThrows(
    () =>
      validateReviewResult({
        ...validEmpty,
        suggestions: [{
          ...validVideoFrame.suggestions[0],
          kind: "price_estimate",
        }],
      }),
    ProviderError,
    "provider_schema_invalid",
  );
});

Deno.test("unknown confidence is schema-invalid", () => {
  assertThrows(
    () =>
      validateReviewResult({
        ...validEmpty,
        suggestions: [{
          ...validVideoFrame.suggestions[0],
          confidence: "certain",
        }],
      }),
    ProviderError,
    "provider_schema_invalid",
  );
});

Deno.test("parseChatCompletion maps finish reasons", () => {
  const parsed = parseChatCompletion(completion(validEmpty, "stop"));
  assertEquals((parsed as { suggestions: unknown[] }).suggestions.length, 0);

  assertThrows(
    () => parseChatCompletion(completion(validEmpty, "length")),
    ProviderError,
    "provider_incomplete",
  );
  assertThrows(
    () => parseChatCompletion(completion(validEmpty, "content_filter")),
    ProviderError,
    "provider_refusal",
  );
  assertThrows(
    () =>
      parseChatCompletion({
        choices: [{ finish_reason: "stop", message: { refusal: "declined" } }],
      }),
    ProviderError,
    "provider_refusal",
  );
  assertThrows(
    () => parseChatCompletion(completion("", "stop")),
    ProviderError,
    "provider_empty",
  );
  assertThrows(
    () => parseChatCompletion(completion("not-json", "stop")),
    ProviderError,
    "provider_invalid_json",
  );
});

Deno.test("HTTP statuses map to stable codes", () => {
  assertEquals(classifyProviderHttpStatus(401).code, "provider_auth");
  assertEquals(classifyProviderHttpStatus(429).code, "provider_quota");
  assertEquals(classifyProviderHttpStatus(500).code, "provider_http");
  assertEquals(errorHttpStatus("provider_timeout"), 504);
  assertEquals(errorHttpStatus("provider_schema_invalid"), 422);
});

Deno.test("diagnostics never keep secrets, media, prompts, or paths", () => {
  const safe = sanitizeFields({
    request_id: "abc",
    path: "/data/user/0/cache/secret.mp4",
    content_base64: "AAAA",
    prompt: "User serial 123",
    authorization: "Bearer sk-secret",
    api_key: "sk-secret",
    image_count: 6,
    encoded_chars: 1200,
  });
  assertEquals(safe.path, undefined);
  assertEquals(safe.content_base64, undefined);
  assertEquals(safe.prompt, undefined);
  assertEquals(safe.authorization, undefined);
  assertEquals(safe.api_key, undefined);
  assertEquals(safe.image_count, 6);
  assertEquals(JSON.stringify(safe).includes("sk-"), false);
  assertEquals(JSON.stringify(safe).includes("/data/user"), false);
});
