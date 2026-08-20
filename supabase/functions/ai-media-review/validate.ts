import { ProviderError } from "./errors.ts";
import {
  CONFIDENCE_VALUES,
  MAX_FRAME_INDEX,
  PHOTO_SLOTS,
  REVIEW_KIND,
  SOURCE_TYPES,
  SUGGESTION_KINDS,
  type ReviewPayload,
} from "./schema.ts";

const KIND_SET = new Set<string>(SUGGESTION_KINDS);
const CONFIDENCE_SET = new Set<string>(CONFIDENCE_VALUES);
const SLOT_SET = new Set<string>(PHOTO_SLOTS);
const SOURCE_SET = new Set<string>(SOURCE_TYPES);

export function validateReviewResult(raw: unknown): ReviewPayload {
  if (raw == null || typeof raw !== "object" || Array.isArray(raw)) {
    throw new ProviderError("provider_schema_invalid", 422);
  }
  const map = raw as Record<string, unknown>;
  const reviewKind = map.review_kind;
  if (reviewKind !== REVIEW_KIND) {
    throw new ProviderError("provider_schema_invalid", 422);
  }
  if (typeof map.disclaimer !== "string" || map.disclaimer.trim() === "") {
    throw new ProviderError("provider_schema_invalid", 422);
  }
  if (!Array.isArray(map.suggestions)) {
    throw new ProviderError("provider_schema_invalid", 422);
  }

  const suggestions: ReviewPayload["suggestions"] = [];
  for (const item of map.suggestions) {
    suggestions.push(validateSuggestion(item));
  }

  return {
    review_kind: REVIEW_KIND,
    disclaimer: map.disclaimer.trim(),
    suggestions,
  };
}

function validateSuggestion(raw: unknown): ReviewPayload["suggestions"][number] {
  if (raw == null || typeof raw !== "object" || Array.isArray(raw)) {
    throw new ProviderError("provider_schema_invalid", 422);
  }
  const map = raw as Record<string, unknown>;
  if (typeof map.id !== "string" || map.id.trim() === "") {
    throw new ProviderError("provider_schema_invalid", 422);
  }
  if (typeof map.kind !== "string" || !KIND_SET.has(map.kind)) {
    throw new ProviderError("provider_schema_invalid", 422);
  }
  if (typeof map.confidence !== "string" || !CONFIDENCE_SET.has(map.confidence)) {
    throw new ProviderError("provider_schema_invalid", 422);
  }
  const value = optionalString(map.value);
  const uncertainty = optionalString(map.uncertainty);
  return {
    id: map.id.trim(),
    kind: map.kind,
    value,
    confidence: map.confidence,
    uncertainty,
    source: validateSource(map.source),
  };
}

function validateSource(raw: unknown): ReviewPayload["suggestions"][number]["source"] {
  if (raw == null || typeof raw !== "object" || Array.isArray(raw)) {
    throw new ProviderError("provider_schema_invalid", 422);
  }
  const map = raw as Record<string, unknown>;
  const type = map.type;
  if (typeof type !== "string" || !SOURCE_SET.has(type)) {
    throw new ProviderError("provider_schema_invalid", 422);
  }
  const label = typeof map.label === "string" ? map.label.trim() : "";
  if (type === "photo") {
    if (typeof map.slot !== "string" || !SLOT_SET.has(map.slot)) {
      throw new ProviderError("provider_schema_invalid", 422);
    }
    return {
      type,
      label: label || map.slot,
      slot: map.slot,
      frame_index: null,
    };
  }
  if (typeof map.frame_index !== "number" || !Number.isInteger(map.frame_index)) {
    throw new ProviderError("provider_schema_invalid", 422);
  }
  if (map.frame_index < 0 || map.frame_index > MAX_FRAME_INDEX) {
    throw new ProviderError("provider_schema_invalid", 422);
  }
  return {
    type,
    label: label || `Walkaround video frame ${map.frame_index + 1}`,
    slot: null,
    frame_index: map.frame_index,
  };
}

function optionalString(raw: unknown): string | null {
  if (raw == null) return null;
  if (typeof raw !== "string") {
    throw new ProviderError("provider_schema_invalid", 422);
  }
  const trimmed = raw.trim();
  return trimmed.length === 0 ? null : trimmed;
}
