// Local OpenAI-compatible Chat Completions stub for the AI Media Review PoC.
//
// The Edge Function calls this with Authorization: Bearer $AI_API_KEY.
// The secret never enters Flutter. Replace this stub with real OpenAI by
// pointing AI_PROVIDER_BASE_URL at https://api.openai.com/v1.

const port = Number(Deno.env.get("POC_STUB_PORT") ?? "8787");
const expectedKey = Deno.env.get("AI_API_KEY")?.trim() ?? "";
if (!expectedKey) {
  console.error("AI_API_KEY is required for the local provider stub");
  Deno.exit(1);
}

Deno.serve({ port }, async (req) => {
  if (req.method !== "POST") {
    return Response.json({ error: "method_not_allowed" }, { status: 405 });
  }
  const auth = req.headers.get("Authorization") ?? "";
  if (auth !== `Bearer ${expectedKey}`) {
    return Response.json({ error: "unauthorized" }, { status: 401 });
  }
  const body = await req.json() as {
    model?: string;
    response_format?: { type?: string };
    messages?: Array<{ role?: string; content?: unknown }>;
  };
  const formatType = body.response_format?.type ?? "json_schema";
  if (formatType !== "json_schema" && formatType !== "json_object") {
    return Response.json({ error: "unsupported_response_format" }, { status: 400 });
  }
  const model = body.model ?? "gpt-4o-mini";
  const user = body.messages?.find((message) => message.role === "user");
  const content = user?.content;
  let imageCount = 0;
  if (Array.isArray(content)) {
    for (const part of content) {
      if (part && typeof part === "object" && "image_url" in part) {
        imageCount += 1;
      }
    }
  }

  const payload = {
    review_kind: "frame_based_video_review",
    disclaimer:
      "AI suggestions only — not verified facts. Humans remain the final authority.",
    suggestions: [
      {
        id: "s-manufacturer",
        kind: "manufacturer",
        value: "Caterpillar",
        confidence: "medium",
        source: {
          type: "photo",
          slot: "front_left_overview",
          frame_index: null,
          label: "Front-left overview",
        },
        uncertainty: "Brand cues inferred from paint and overall shape only.",
      },
      {
        id: "s-frame",
        kind: "visible_damage_or_wear",
        value: "Possible surface wear visible in walkaround frames",
        confidence: "low",
        source: {
          type: "video_frame",
          slot: null,
          frame_index: 0,
          label: "Walkaround video frame 1",
        },
        uncertainty: `Frame-based review of ${imageCount} stills.`.slice(0, 240),
      },
      {
        id: "s-unreadable",
        kind: "unreadable_or_uncertain",
        value: null,
        confidence: "low",
        source: {
          type: "photo",
          slot: "serial_data_plate",
          frame_index: null,
          label: "Serial / data plate",
        },
        uncertainty:
          "Serial characters were not clear enough to suggest without inventing digits.",
      },
    ],
    stub: {
      model,
      image_count: imageCount,
      note: "local openai-compatible stub; swap AI_PROVIDER_BASE_URL for real OpenAI",
    },
  };

  return Response.json({
    choices: [
      {
        finish_reason: "stop",
        message: {
          role: "assistant",
          content: JSON.stringify(payload),
        },
      },
    ],
  });
});

console.log(`OpenAI-compatible stub listening on http://127.0.0.1:${port}`);
