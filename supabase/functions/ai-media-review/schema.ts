export const PHOTO_SLOTS = [
  "front_left_overview",
  "rear_right_overview",
  "serial_data_plate",
  "hour_meter_dashboard",
] as const;

export const SUGGESTION_KINDS = [
  "manufacturer",
  "model",
  "serial_number",
  "hour_meter",
  "visible_damage_or_wear",
  "possible_leak",
  "possible_crack",
  "rust",
  "dent",
  "broken_glass_or_light",
  "tire_or_track_wear",
  "visible_attachment",
  "unreadable_or_uncertain",
] as const;

export const CONFIDENCE_VALUES = ["high", "medium", "low"] as const;
export const SOURCE_TYPES = ["photo", "video_frame"] as const;
export const REVIEW_KIND = "frame_based_video_review";
export const MAX_FRAME_INDEX = 5;

export const SYSTEM_PROMPT =
  `You review heavy-equipment inspection still photos and extracted walkaround video frames.
Return only the structured JSON schema. These are AI suggestions for a human, not verified facts.
Rules:
- Never invent missing serial characters or hour-meter digits.
- Preserve ambiguous characters such as O/0, I/1, S/5, B/8 exactly as seen.
- Do not estimate price or valuation.
- Do not assign Good/Fair/Poor ratings.
- Do not claim mechanical safety, certification, or airworthiness from photos.
- Do not describe or identify people or faces.
- Walkaround input is frame-based video review: still frames only, not a full video.
- Walkaround evidence MUST use source.type = "video_frame" and include frame_index (0-5).
- Photo evidence MUST use source.type = "photo" and a supported slot: front_left_overview, rear_right_overview, serial_data_plate, hour_meter_dashboard.
- Never force a suggestion. If nothing reliable is visible, return suggestions: [].
- Unreadable or irrelevant media returns an empty suggestions array. Do not invent content.`;

/**
 * OpenAI Structured Outputs schema. Every object sets additionalProperties
 * false. Optional fields are typed as T | null and listed in required.
 */
export const REVIEW_JSON_SCHEMA = {
  type: "object",
  additionalProperties: false,
  required: ["review_kind", "disclaimer", "suggestions"],
  properties: {
    review_kind: {
      type: "string",
      enum: [REVIEW_KIND],
    },
    disclaimer: {
      type: "string",
    },
    suggestions: {
      type: "array",
      items: {
        type: "object",
        additionalProperties: false,
        required: [
          "id",
          "kind",
          "value",
          "confidence",
          "source",
          "uncertainty",
        ],
        properties: {
          id: { type: "string" },
          kind: { type: "string", enum: [...SUGGESTION_KINDS] },
          value: { type: ["string", "null"] },
          confidence: { type: "string", enum: [...CONFIDENCE_VALUES] },
          uncertainty: { type: ["string", "null"] },
          source: {
            type: "object",
            additionalProperties: false,
            required: ["type", "label", "slot", "frame_index"],
            properties: {
              type: { type: "string", enum: [...SOURCE_TYPES] },
              label: { type: "string" },
              slot: {
                anyOf: [
                  { type: "string", enum: [...PHOTO_SLOTS] },
                  { type: "null" },
                ],
              },
              frame_index: {
                anyOf: [
                  { type: "integer", minimum: 0, maximum: MAX_FRAME_INDEX },
                  { type: "null" },
                ],
              },
            },
          },
        },
      },
    },
  },
} as const;

export type ReviewPayload = {
  review_kind: string;
  disclaimer: string;
  suggestions: Array<{
    id: string;
    kind: string;
    value: string | null;
    confidence: string;
    uncertainty: string | null;
    source: {
      type: string;
      label: string;
      slot: string | null;
      frame_index: number | null;
    };
  }>;
};
