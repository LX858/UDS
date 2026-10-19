import {
  LR_BRIDGE_ENDPOINT,
  NUI_PAYLOAD_MAX_BYTES,
  NUI_VERSION,
} from './contracts';
import {
  assertPayloadSize,
  isWithinPayloadLimit,
  parseEnvelope,
} from './runtime.protocol';
import {
  NuiRuntimeError,
  type NuiBrowserMockStateResult,
  type NuiBrowserMockStateWrite,
  type NuiEnvelope,
} from './runtime.types';

export async function postEnvelope(
  resourceName: string,
  timeoutMs: number,
  envelope: NuiEnvelope<string>,
  pendingControllers: Set<AbortController>
): Promise<NuiEnvelope<string>> {
  assertPayloadSize(envelope.payload);
  const controller = new AbortController();
  pendingControllers.add(controller);
  const timer = window.setTimeout(
    () =>
      controller.abort(
        new NuiRuntimeError('timeout', 'NUI bridge request timed out')
      ),
    timeoutMs
  );
  try {
    const response = await fetch(
      `https://${resourceName}/${LR_BRIDGE_ENDPOINT}`,
      {
        method: 'post',
        headers: {'Content-Type': 'application/json; charset=UTF-8'},
        body: JSON.stringify(envelope),
        signal: controller.signal,
      }
    );
    if (!response.ok) {
      throw new NuiRuntimeError(
        'rpc_failed',
        `Bridge returned ${response.status}`,
        {status: response.status}
      );
    }
    let responseData: unknown;
    try {
      responseData = await response.json();
    } catch (error) {
      throw new NuiRuntimeError(
        'invalid_response',
        'Bridge response is not valid JSON',
        error
      );
    }
    if (!isWithinPayloadLimit(responseData)) {
      throw new NuiRuntimeError(
        'invalid_response',
        `NUI response exceeds ${NUI_PAYLOAD_MAX_BYTES} bytes`
      );
    }
    const parsed = parseEnvelope(responseData);
    if (!parsed) {
      throw new NuiRuntimeError(
        'invalid_response',
        'Invalid bridge response envelope'
      );
    }
    return parsed;
  } catch (error) {
    if (controller.signal.aborted) {
      const reason = controller.signal.reason;
      throw reason instanceof NuiRuntimeError
        ? reason
        : new NuiRuntimeError('timeout', 'NUI bridge request timed out', reason);
    }
    throw error;
  } finally {
    window.clearTimeout(timer);
    pendingControllers.delete(controller);
  }
}

export async function dispatchMockRpc(
  module: string,
  name: string,
  requestId: string,
  payload: unknown,
  handler: (payload: unknown) => Promise<unknown> | unknown,
  timeoutMs: number,
  pendingControllers: Set<AbortController>
): Promise<NuiEnvelope<string>> {
  const controller = new AbortController();
  pendingControllers.add(controller);
  const timer = window.setTimeout(
    () =>
      controller.abort(new NuiRuntimeError('timeout', 'Browser mock RPC timed out')),
    timeoutMs
  );
  const aborted = new Promise<never>((_resolve, reject) => {
    controller.signal.addEventListener(
      'abort',
      () =>
        reject(
          controller.signal.reason instanceof NuiRuntimeError
            ? controller.signal.reason
            : new NuiRuntimeError('timeout', 'Browser mock RPC timed out')
        ),
      {once: true}
    );
  });
  try {
    const responsePayload = await Promise.race([
      Promise.resolve().then(() => handler(payload)),
      aborted,
    ]);
    return {
      version: NUI_VERSION,
      module,
      kind: 'rpc.response',
      name,
      requestId,
      payload: responsePayload,
    };
  } finally {
    window.clearTimeout(timer);
    pendingControllers.delete(controller);
  }
}

export async function dispatchMockState(
  request: NuiBrowserMockStateWrite,
  handler: (
    request: NuiBrowserMockStateWrite
  ) => NuiBrowserMockStateResult | Promise<NuiBrowserMockStateResult>,
  timeoutMs: number,
  pendingControllers: Set<AbortController>
): Promise<NuiEnvelope<string>> {
  const controller = new AbortController();
  pendingControllers.add(controller);
  const timer = window.setTimeout(
    () =>
      controller.abort(
        new NuiRuntimeError('timeout', 'Browser mock state write timed out')
      ),
    timeoutMs
  );
  const aborted = new Promise<never>((_resolve, reject) => {
    controller.signal.addEventListener(
      'abort',
      () =>
        reject(
          controller.signal.reason instanceof NuiRuntimeError
            ? controller.signal.reason
            : new NuiRuntimeError('timeout', 'Browser mock state write timed out')
        ),
      {once: true}
    );
  });
  try {
    const result = await Promise.race([
      Promise.resolve().then(() => handler(request)),
      aborted,
    ]);
    return {
      version: NUI_VERSION,
      module: request.module,
      kind: 'rpc.response',
      name: request.name,
      requestId: request.requestId,
      sessionId: request.sessionId,
      revision: result.revision,
      payload: result.payload,
    };
  } finally {
    window.clearTimeout(timer);
    pendingControllers.delete(controller);
  }
}
