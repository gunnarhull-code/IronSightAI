#!/usr/bin/env bash
# Local AI Media Review proof-of-concept demo.
#
# Exact setup (repo root):
#
#   cp .env.example .env
#   sudo service docker start
#   npx supabase start
#   export PATH="$HOME/flutter/bin:$HOME/.deno/bin:$PATH"
#
#   # Terminal A — OpenAI-compatible stub (holds/checks server-side secret):
#   AI_API_KEY=local-poc-secret deno run -A scripts/ai_media_review_openai_stub.ts
#
#   # Terminal B — Edge Function with server-side secret (not in Flutter):
#   # Point AI_PROVIDER_BASE_URL at the Docker host gateway that can reach the stub
#   # (often http://172.18.0.1:8787/v1 or http://172.17.0.1:8787/v1).
#   npx supabase functions serve ai-media-review --env-file supabase/.env.ai-media-review.local
#
#   # Terminal C — decode MP4 frames + call Edge Function:
#   ./scripts/ai_media_review_poc_demo.sh
#
# Real OpenAI (founder-supplied key only):
#   Set AI_API_KEY=sk-... and AI_PROVIDER_BASE_URL=https://api.openai.com/v1
#   in supabase/.env.ai-media-review.local (never in Flutter .env).
#
set -euo pipefail
ROOT="$(cd "$(dirname "$0")/.." && pwd)"
cd "$ROOT"
export PATH="${HOME}/flutter/bin:${HOME}/.deno/bin:${PATH}"

WORK="$(mktemp -d /tmp/ironsight-ai-poc-XXXXXX)"
trap 'rm -rf "$WORK"' EXIT

echo "== Building sample inspection photo and walkaround MP4 =="
ffmpeg -hide_banner -loglevel error -f lavfi -i color=c=gray:s=640x480:d=0.1 \
  -frames:v 1 -y "$WORK/front_left.jpg"
ffmpeg -hide_banner -loglevel error -f lavfi -i color=c=red:s=320x240:d=1 -pix_fmt yuv420p -y "$WORK/r.mp4"
ffmpeg -hide_banner -loglevel error -f lavfi -i color=c=green:s=320x240:d=1 -pix_fmt yuv420p -y "$WORK/g.mp4"
ffmpeg -hide_banner -loglevel error -f lavfi -i color=c=blue:s=320x240:d=1 -pix_fmt yuv420p -y "$WORK/b.mp4"
printf "file '%s'\nfile '%s'\nfile '%s'\n" "$WORK/r.mp4" "$WORK/g.mp4" "$WORK/b.mp4" >"$WORK/list.txt"
ffmpeg -hide_banner -loglevel error -f concat -safe 0 -i "$WORK/list.txt" -c copy -y "$WORK/walkaround.mp4"

echo "== Decoding up to 6 frames from the recorded MP4 =="
dart run "$ROOT/scripts/decode_walkaround_frames.dart" \
  --video "$WORK/walkaround.mp4" \
  --duration-ms 3000 \
  --out-dir "$WORK/frames" \
  --manifest "$WORK/manifest.json"

echo "== Ensuring local auth user + company for tenant check =="
source <(grep -E '^(SUPABASE_URL|SUPABASE_ANON_KEY)=' .env | sed 's/^/export /')
EMAIL="ai-poc-$(date +%s)@example.com"
PASSWORD="password123"
SIGNUP="$(curl -sS -X POST "$SUPABASE_URL/auth/v1/signup" \
  -H "apikey: $SUPABASE_ANON_KEY" \
  -H "Content-Type: application/json" \
  -d "{\"email\":\"$EMAIL\",\"password\":\"$PASSWORD\"}")"
ACCESS_TOKEN="$(python3 - <<PY
import json
print(json.loads('''$SIGNUP''').get("access_token") or "")
PY
)"
if [[ -z "$ACCESS_TOKEN" ]]; then
  LOGIN="$(curl -sS -X POST "$SUPABASE_URL/auth/v1/token?grant_type=password" \
    -H "apikey: $SUPABASE_ANON_KEY" \
    -H "Content-Type: application/json" \
    -d "{\"email\":\"$EMAIL\",\"password\":\"$PASSWORD\"}")"
  ACCESS_TOKEN="$(python3 - <<PY
import json
print(json.loads('''$LOGIN''').get("access_token") or "")
PY
)"
fi
test -n "$ACCESS_TOKEN"

COMPANY="$(curl -sS -X POST "$SUPABASE_URL/rest/v1/rpc/create_company_for_current_user" \
  -H "apikey: $SUPABASE_ANON_KEY" \
  -H "Authorization: Bearer $ACCESS_TOKEN" \
  -H "Content-Type: application/json" \
  -d '{"p_name":"AI PoC Co"}')"
COMPANY_ID="$(python3 - <<PY
import json
raw = '''$COMPANY'''
data = json.loads(raw)
if isinstance(data, list):
  data = data[0]
print(data.get("id") or "")
PY
)"
test -n "$COMPANY_ID"
echo "$COMPANY_ID" >"$WORK/company_id.txt"
echo "company_id=$COMPANY_ID"

echo "== Building Edge Function payload (stills only; no video bytes) =="
python3 - <<PY
import base64, json, pathlib
work = pathlib.Path("$WORK")
manifest = json.loads((work / "manifest.json").read_text())
photo = (work / "front_left.jpg").read_bytes()
images = [{
  "id": "photo-front-left",
  "role": "photo",
  "label": "Front-left overview",
  "slot": "front_left_overview",
  "mime_type": "image/jpeg",
  "byte_length": len(photo),
  "content_base64": base64.b64encode(photo).decode("ascii"),
}]
for i, frame in enumerate(manifest["frames"]):
    raw = pathlib.Path(frame["path"]).read_bytes()
    images.append({
      "id": f"walkaround-frame-{i}",
      "role": "video_frame",
      "label": f"Walkaround video frame {i + 1}",
      "frame_index": i,
      "mime_type": "image/jpeg",
      "byte_length": len(raw),
      "content_base64": base64.b64encode(raw).decode("ascii"),
    })
payload = {
  "company_id": (work / "company_id.txt").read_text().strip(),
  "inspection_id": "demo-inspection",
  "review_kind": "frame_based_video_review",
  "includes_video_frames": True,
  "images": images,
}
assert "video" not in payload and "video_base64" not in payload
assert all(not str(img["mime_type"]).startswith("video/") for img in images)
assert manifest["video_path"] not in json.dumps(payload)
assert manifest["frames_decoded_from_local_video"] is True
(work / "payload.json").write_text(json.dumps(payload))
print(f"images={len(images)} video_frames={sum(1 for i in images if i['role']=='video_frame')}")
print(f"source_video={manifest['video_path']}")
print("original_video_included=false")
PY

FUNCTION_URL="${FUNCTION_URL:-$SUPABASE_URL/functions/v1/ai-media-review}"
echo "== Calling Edge Function $FUNCTION_URL =="
curl -sS -X POST "$FUNCTION_URL" \
  -H "Authorization: Bearer $ACCESS_TOKEN" \
  -H "apikey: $SUPABASE_ANON_KEY" \
  -H "Content-Type: application/json" \
  --data-binary @"$WORK/payload.json" | tee "$WORK/response.json"

python3 - <<PY
import json, pathlib
body = json.loads(pathlib.Path("$WORK/response.json").read_text())
assert "error" not in body, body
assert isinstance(body.get("suggestions"), list) and body["suggestions"], body
provider = body.get("provider") or {}
print("provider_kind=", provider.get("kind"))
print("provider_model=", provider.get("model"))
print("provider_base_url=", provider.get("base_url"))
print("suggestion_count=", len(body["suggestions"]))
for item in body["suggestions"]:
    print("-", item.get("kind"), item.get("confidence"), item.get("source"))
print("ok")
PY
