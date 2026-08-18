export type ProviderErrorCode =
  | "provider_timeout"
  | "provider_auth"
  | "provider_quota"
  | "provider_http"
  | "provider_empty"
  | "provider_refusal"
  | "provider_incomplete"
  | "provider_invalid_json"
  | "provider_schema_invalid"
  | "provider_unconfigured"
  | "provider_failure";

export class ProviderError extends Error {
  constructor(
    readonly code: ProviderErrorCode,
    readonly httpStatus: number,
  ) {
    super(code);
    this.name = "ProviderError";
  }
}

export function classifyProviderHttpStatus(status: number): ProviderError {
  if (status === 401 || status === 403) {
    return new ProviderError("provider_auth", 502);
  }
  if (status === 429) {
    return new ProviderError("provider_quota", 502);
  }
  return new ProviderError("provider_http", 502);
}

export function errorHttpStatus(code: ProviderErrorCode): number {
  switch (code) {
    case "provider_timeout":
      return 504;
    case "provider_unconfigured":
      return 503;
    case "provider_invalid_json":
    case "provider_schema_invalid":
      return 422;
    default:
      return 502;
  }
}
