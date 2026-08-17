// Swappable server-side AI provider for media review.
// Flutter never calls this. Credentials stay in Edge Function secrets.

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
  companyId: string;
  inspectionId: string;
  images: ProviderImage[];
}

export interface ProviderAdapter {
  analyze(request: ProviderRequest): Promise<unknown>;
}

const SYSTEM_PROMPT = `You review heavy-equipment inspection still photos and extracted walkaround video frames.
Return JSON only. These are AI suggestions for a human, not verified facts.
Rules:
- Never invent missing serial characters or hour-meter digits.
- Preserve ambiguous characters such as O/0, I/1, S/5, B/8 exactly as seen.
- If a serial or hour reading is partial or unreadable, use kind unreadable_or_uncertain and omit a guessed value.
- Do not estimate price or valuation.
- Do not assign Good/Fair/Poor ratings.
- Do not claim mechanical safety, certification, or airworthiness from photos.
- Do not describe or identify people or faces.
- Walkaround input is frame-based video review: still frames only, not a full video.
- Every suggestion needs confidence high|medium|low, a source photo slot or video frame, and an uncertainty explanation when confidence is not high.
JSON shape:
{"review_kind":"frame_based_video_review","disclaimer":"AI suggestions only — not verified facts.","suggestions":[{"id":"s1","kind":"manufacturer|model|serial_number|hour_meter|visible_damage_or_wear|possible_leak|possible_crack|rust|dent|broken_glass_or_light|tire_or_track_wear|visible_attachment|unreadable_or_uncertain","value":"string or omit","confidence":"high","source":{"type":"photo","slot":"front_left_overview","label":"Front-left overview"},"uncertainty":"optional"}]}`;

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
          `Company-scoped inspection ${request.inspectionId}. ` +
          `Analyze only the still images. Frame-based video review. ` +
          `Image labels: ${
            request.images.map((image) => image.label).join("; ")
          }`,
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

    const response = await fetch(`${this.baseUrl}/chat/completions`, {
      method: "POST",
      headers: {
        Authorization: `Bearer ${this.apiKey}`,
        "Content-Type": "application/json",
      },
      body: JSON.stringify({
        model: this.model,
        temperature: 0,
        response_format: { type: "json_object" },
        max_tokens: 2000,
        messages: [
          { role: "system", content: SYSTEM_PROMPT },
          { role: "user", content },
        ],
      }),
    });

    if (!response.ok) {
      throw new Error(`provider_http_${response.status}`);
    }
    const body = await response.json() as {
      choices?: Array<{ message?: { content?: string } }>;
    };
    const text = body.choices?.[0]?.message?.content;
    if (!text) {
      throw new Error("provider_empty");
    }
    return JSON.parse(text);
  }
}
