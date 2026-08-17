import { createClient } from "https://esm.sh/@supabase/supabase-js@2";
import {
  createProviderAdapter,
  ProviderImage,
  ProviderUnconfiguredError,
} from "./provider.ts";

const MAX_IMAGES = 10;
const MAX_BYTES_PER_IMAGE = 400 * 1024;
const MAX_BODY_BYTES = 4.5 * 1024 * 1024;

const corsHeaders = {
  "Access-Control-Allow-Origin": "*",
  "Access-Control-Allow-Headers":
    "authorization, x-client-info, apikey, content-type",
};

Deno.serve(async (req) => {
  if (req.method === "OPTIONS") {
    return new Response("ok", { headers: corsHeaders });
  }

  try {
    if (req.method !== "POST") {
      return json({ error: "method_not_allowed" }, 405);
    }

    const contentLength = Number(req.headers.get("content-length") ?? "0");
    if (contentLength > MAX_BODY_BYTES) {
      return json({ error: "payload_too_large" }, 413);
    }

    const authHeader = req.headers.get("Authorization") ?? "";
    const jwt = authHeader.replace(/^Bearer\s+/i, "").trim();
    if (!jwt) {
      return json({ error: "unauthorized" }, 401);
    }

    const supabaseUrl = Deno.env.get("SUPABASE_URL") ?? "";
    const supabaseAnon = Deno.env.get("SUPABASE_ANON_KEY") ?? "";
    const supabase = createClient(supabaseUrl, supabaseAnon, {
      global: { headers: { Authorization: `Bearer ${jwt}` } },
    });

    const { data: userData, error: userError } = await supabase.auth.getUser(
      jwt,
    );
    if (userError || !userData.user) {
      return json({ error: "unauthorized" }, 401);
    }

    const payload = await req.json() as Record<string, unknown>;
    if (hasVideoUpload(payload)) {
      return json({ error: "video_upload_not_allowed" }, 400);
    }

    const companyId = stringField(payload.company_id);
    const inspectionId = stringField(payload.inspection_id);
    if (!companyId || !inspectionId) {
      return json({ error: "invalid_request" }, 400);
    }

    const { data: profile, error: profileError } = await supabase
      .from("user_profiles")
      .select("company_id")
      .eq("id", userData.user.id)
      .maybeSingle();
    if (profileError || !profile?.company_id) {
      return json({ error: "forbidden" }, 403);
    }
    if (profile.company_id !== companyId) {
      return json({ error: "tenant_mismatch" }, 403);
    }

    const images = parseImages(payload.images);
    if (images.length === 0) {
      return json({ error: "no_media" }, 400);
    }

    const adapter = createProviderAdapter();
    const result = await adapter.analyze({
      companyId,
      inspectionId,
      images,
    });
    return json(result, 200);
  } catch (error) {
    if (error instanceof ProviderUnconfiguredError) {
      return json({ error: "provider_unconfigured" }, 503);
    }
    return json({ error: "provider_failure" }, 502);
  }
});

function json(body: unknown, status: number): Response {
  return new Response(JSON.stringify(body), {
    status,
    headers: { ...corsHeaders, "Content-Type": "application/json" },
  });
}

function stringField(value: unknown): string | null {
  if (typeof value !== "string") return null;
  const trimmed = value.trim();
  return trimmed.length === 0 ? null : trimmed;
}

function hasVideoUpload(payload: Record<string, unknown>): boolean {
  if ("video" in payload || "video_base64" in payload || "video_bytes" in payload) {
    return true;
  }
  const images = payload.images;
  if (!Array.isArray(images)) return false;
  return images.some((item) => {
    if (!item || typeof item !== "object") return false;
    const mime = String((item as { mime_type?: unknown }).mime_type ?? "")
      .toLowerCase();
    return mime.startsWith("video/");
  });
}

function parseImages(raw: unknown): ProviderImage[] {
  if (!Array.isArray(raw) || raw.length > MAX_IMAGES) {
    throw new Error("invalid_images");
  }
  const images: ProviderImage[] = [];
  for (const item of raw) {
    if (!item || typeof item !== "object") {
      throw new Error("invalid_images");
    }
    const row = item as Record<string, unknown>;
    const mime = stringField(row.mime_type) ?? "image/jpeg";
    if (mime.startsWith("video/")) {
      throw new Error("video_upload_not_allowed");
    }
    const content = stringField(row.content_base64);
    if (!content) throw new Error("invalid_images");
    const approxBytes = Math.floor(content.length * 0.75);
    if (approxBytes > MAX_BYTES_PER_IMAGE) {
      throw new Error("image_too_large");
    }
    images.push({
      id: stringField(row.id) ?? `img-${images.length}`,
      role: stringField(row.role) ?? "photo",
      label: stringField(row.label) ?? "Inspection still",
      slot: stringField(row.slot) ?? undefined,
      frame_index: typeof row.frame_index === "number"
        ? row.frame_index
        : undefined,
      mime_type: mime,
      content_base64: content,
    });
  }
  return images;
}
