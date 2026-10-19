import {
  NUI_PAYLOAD_MAX_BYTES,
  NUI_RPC_TIMEOUT_MAX_MS,
  NUI_VERSION,
  type NuiKind,
} from './contracts';
import {NuiRuntimeError, type NuiEnvelope} from './runtime.types';

const IDENTIFIER_PATTERN = /^[a-z][A-Za-z0-9_]*$/;

export function normalizeRuntimeError(
  error: unknown,
  fallbackCode: 'invalid_response' | 'rpc_failed',
  fallbackMessage: string
) {
  return error instanceof NuiRuntimeError
    ? error
    : new NuiRuntimeError(fallbackCode, fallbackMessage, error);
}

export function parseEnvelope(data: unknown): NuiEnvelope<string> | null {
  if (!data || typeof data !== 'object') return null;
  const record = data as Record<string, unknown>;
  const allowedKeys = new Set([
    'version',
    'module',
    'kind',
    'name',
    'requestId',
    'sessionId',
    'revision',
    'payload',
    'error',
  ]);
  if (!Object.keys(record).every(key => allowedKeys.has(key))) return null;
  if (
    record.version !== NUI_VERSION ||
    !isIdentifier(record.module, true) ||
    !isKind(record.kind) ||
    !isIdentifier(record.name)
  ) {
    return null;
  }
  if (
    'requestId' in record &&
    (typeof record.requestId !== 'string' ||
      record.requestId.length === 0 ||
      record.requestId.length > 128)
  ) {
    return null;
  }
  if (
    'sessionId' in record &&
    (typeof record.sessionId !== 'string' ||
      record.sessionId.length === 0 ||
      record.sessionId.length > 128)
  ) {
    return null;
  }
  if ('revision' in record && !isPositiveInteger(record.revision)) return null;
  if ('error' in record && !isEnvelopeError(record.error)) return null;
  return {
    version: NUI_VERSION,
    module: record.module,
    kind: record.kind,
    name: record.name,
    ...('requestId' in record ? {requestId: record.requestId as string} : {}),
    ...('sessionId' in record ? {sessionId: record.sessionId as string} : {}),
    ...('revision' in record ? {revision: record.revision as number} : {}),
    ...('payload' in record ? {payload: record.payload} : {}),
    ...('error' in record
      ? {error: record.error as {code: string; message?: string}}
      : {}),
  };
}

export function rpcResponseEnvelope(
  module: string,
  name: string,
  requestId: string
) {
  return {version: NUI_VERSION, module, name, requestId};
}

export function normalizeTimeout(timeoutMs: number) {
  if (!Number.isFinite(timeoutMs) || timeoutMs <= 0) {
    throw new NuiRuntimeError('invalid_envelope', 'RPC timeout must be positive');
  }
  return Math.min(timeoutMs, NUI_RPC_TIMEOUT_MAX_MS);
}

export function assertPayloadSize(payload: unknown) {
  if (!isWithinPayloadLimit(payload)) {
    throw new NuiRuntimeError(
      'invalid_payload',
      `NUI payload exceeds ${NUI_PAYLOAD_MAX_BYTES} bytes`
    );
  }
}

export function isWithinPayloadLimit(payload: unknown) {
  try {
    return (
      new TextEncoder().encode(JSON.stringify(payload ?? null)).byteLength <=
      NUI_PAYLOAD_MAX_BYTES
    );
  } catch {
    return false;
  }
}

export function isPositiveInteger(value: unknown): value is number {
  return typeof value === 'number' && Number.isSafeInteger(value) && value > 0;
}

export function cloneValue<T>(value: T): T {
  return structuredClone(value);
}

export function getParentResourceName() {
  const candidate = (window as {GetParentResourceName?: () => string})
    .GetParentResourceName;
  return candidate ? candidate() : 'nui-frame-app';
}

export function createSessionSalt() {
  return globalThis.crypto?.randomUUID?.() ?? Math.random().toString(36).slice(2);
}

function isIdentifier(value: unknown, allowCore = false): value is string {
  return (
    typeof value === 'string' &&
    value.length <= 64 &&
    ((allowCore && value === 'core') || IDENTIFIER_PATTERN.test(value))
  );
}

function isKind(value: unknown): value is NuiKind {
  return (
    value === 'state.snapshot' ||
    value === 'state.set' ||
    value === 'state.patch' ||
    value === 'event' ||
    value === 'rpc.request' ||
    value === 'rpc.response' ||
    value === 'rpc.error'
  );
}

function isEnvelopeError(
  value: unknown
): value is {code: string; message?: string} {
  if (typeof value !== 'object' || value === null) return false;
  const error = value as Record<string, unknown>;
  return (
    Object.keys(error).every(key => key === 'code' || key === 'message') &&
    typeof error.code === 'string' &&
    error.code.length > 0 &&
    error.code.length <= 64 &&
    (!('message' in error) ||
      (typeof error.message === 'string' && error.message.length <= 512))
  );
}
