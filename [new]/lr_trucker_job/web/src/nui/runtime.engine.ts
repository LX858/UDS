import type {
  ContractSchema,
  ModuleContractInput,
  RpcContract,
  StateContract,
} from '@lr/contracts';
import {
  NUI_RPC_TIMEOUT_MS,
  NUI_VERSION,
  compileValidator,
  generatedContracts,
} from './contracts';
import {
  assertPayloadSize,
  cloneValue,
  createSessionSalt,
  getParentResourceName,
  isPositiveInteger,
  isWithinPayloadLimit,
  normalizeRuntimeError,
  normalizeTimeout,
  parseEnvelope,
  rpcResponseEnvelope,
} from './runtime.protocol';
import {
  dispatchMockRpc,
  dispatchMockState,
  postEnvelope,
} from './runtime.transport';
import {
  NuiRuntimeError,
  type GeneratedNuiModules,
  type NuiEnvelope,
  type NuiRuntime,
  type NuiRuntimeOptions,
  type NuiSubscription,
} from './runtime.types';

type ContractRegistry = Readonly<Record<string, ModuleContractInput>>;
type Validator = (payload: unknown) => boolean;
type Listener = (payload: never) => void;
type RpcHandler = (payload: never) => Promise<unknown> | unknown;

interface CompiledState {
  contract: StateContract;
  validate: Validator;
  validatePatch?: Validator;
}

interface CompiledRpc {
  contract: RpcContract;
  request: Validator;
  response: Validator;
}

interface CompiledModule {
  contract: ModuleContractInput;
  state: Record<string, CompiledState>;
  eventsToNui: Record<string, Validator>;
  eventsToClient: Record<string, Validator>;
  rpcToNui: Record<string, CompiledRpc>;
  rpcToClient: Record<string, CompiledRpc>;
  canonical: Record<string, unknown>;
  values: Record<string, unknown>;
}

interface PendingWrite {
  readonly kind: 'state.set' | 'state.patch';
  readonly payload: unknown;
}

export function createNuiRuntime<
  Contracts extends ContractRegistry = typeof generatedContracts,
>(options: NuiRuntimeOptions<Contracts> = {}): NuiRuntime<Contracts> {
  const contracts = (options.contracts ?? generatedContracts) as Contracts;
  const resourceName = options.resourceName ?? getParentResourceName();
  const configuredTimeout =
    options.timeoutMs === undefined ? undefined : normalizeTimeout(options.timeoutMs);
  const modules = compileModules(contracts);
  const subscribers = new Map<string, Set<Listener>>();
  const rpcHandlers = new Map<string, RpcHandler>();
  const revisions = new Map<string, number>();
  const writeQueues = new Map<string, Promise<void>>();
  const pendingWrites = new Map<string, PendingWrite[]>();
  const mockRevisions = new Map<string, number>();
  const pendingControllers = new Set<AbortController>();
  const handledRequests = new Set<string>();
  const handledRequestOrder: string[] = [];
  const notificationQueue: Array<{key: string; payload: unknown}> = [];
  const sessionId = createSessionSalt();
  let requestCounter = 0;
  let disposed = false;
  let notifying = false;
  let synced = false;
  let readyPromise: Promise<boolean> | undefined;
  let resolveSynced: (() => void) | undefined;
  let rejectSynced: ((error: NuiRuntimeError) => void) | undefined;
  let syncedTimer: number | undefined;

  const reportError = (error: NuiRuntimeError) => options.onError?.(error);
  const assertActive = () => {
    if (disposed) {
      throw new NuiRuntimeError('disposed', 'NUI runtime is disposed');
    }
  };
  const stateKey = (module: string, name: string) =>
    `${module}:state:${name}`;
  const eventKey = (module: string, name: string) =>
    `${module}:event:${name}`;
  const rpcKey = (module: string, name: string) => `${module}:rpc:${name}`;

  const notify = (key: string, payload: unknown) => {
    notificationQueue.push({key, payload: cloneValue(payload)});
    if (notifying) return;

    notifying = true;
    try {
      while (notificationQueue.length > 0) {
        const notification = notificationQueue.shift()!;
        for (const listener of [...(subscribers.get(notification.key) ?? [])]) {
          try {
            listener(cloneValue(notification.payload) as never);
          } catch (error) {
            reportError(
              new NuiRuntimeError(
                'subscriber_failed',
                `NUI subscriber failed for ${notification.key}`,
                error
              )
            );
          }
        }
      }
    } finally {
      notificationQueue.length = 0;
      notifying = false;
    }
  };

  const refreshEffectiveValue = (
    module: CompiledModule,
    name: string,
    key: string
  ) => {
    const state = module.state[name]!;
    let value = cloneValue(module.canonical[name]);
    for (const write of pendingWrites.get(key) ?? []) {
      value = applyStateWrite(value, write);
    }
    if (!state.validate(value)) {
      throw new NuiRuntimeError(
        'invalid_payload',
        `Invalid optimistic state for ${module.contract.id}.${name}`,
        value
      );
    }
    module.values[name] = cloneValue(value);
    notify(key, value);
  };

  const subscribe = (
    key: string,
    listener: (payload: never) => void
  ): NuiSubscription => {
    assertActive();
    const listeners = subscribers.get(key) ?? new Set<Listener>();
    listeners.add(listener);
    subscribers.set(key, listeners);
    let active = true;
    return {
      dispose() {
        if (!active) return;
        active = false;
        listeners.delete(listener);
        if (listeners.size === 0) subscribers.delete(key);
      },
    };
  };

  const post = (envelope: NuiEnvelope<string>) => {
    assertActive();
    assertPayloadSize(envelope.payload);
    return postEnvelope(
      resourceName,
      configuredTimeout ?? NUI_RPC_TIMEOUT_MS,
      envelope,
      pendingControllers
    );
  };

  const invalidPayload = (envelope: NuiEnvelope<string>) => {
    reportError(
      new NuiRuntimeError(
        'invalid_payload',
        `Invalid payload for ${envelope.module}.${envelope.name}`,
        envelope.payload
      )
    );
    return false;
  };

  const receiveState = (
    module: CompiledModule,
    envelope: NuiEnvelope<string>
  ) => {
    const state = module.state[envelope.name];
    if (!state || envelope.sessionId !== sessionId) return invalidPayload(envelope);
    const revisionKey = stateKey(envelope.module, envelope.name);
    if (!isPositiveInteger(envelope.revision)) return invalidPayload(envelope);
    if (envelope.revision <= (revisions.get(revisionKey) ?? 0)) return false;

    if (!state.validate(envelope.payload)) return invalidPayload(envelope);
    const nextValue = envelope.payload;

    revisions.set(revisionKey, envelope.revision);
    module.canonical[envelope.name] = cloneValue(nextValue);
    refreshEffectiveValue(module, envelope.name, revisionKey);
    return true;
  };

  const receiveEvent = (
    module: CompiledModule,
    envelope: NuiEnvelope<string>
  ) => {
    const validate = module.eventsToNui[envelope.name];
    if (!validate?.(envelope.payload)) return invalidPayload(envelope);
    notify(eventKey(envelope.module, envelope.name), envelope.payload);
    return true;
  };

  const receiveRpc = async (
    module: CompiledModule,
    envelope: NuiEnvelope<string>
  ) => {
    const endpoint = module.rpcToNui[envelope.name];
    if (!endpoint || !envelope.requestId || !endpoint.request(envelope.payload)) {
      invalidPayload(envelope);
      return;
    }
    const correlation = `${envelope.module}:${envelope.name}:${envelope.requestId}`;
    if (handledRequests.has(correlation)) return;
    rememberRequest(correlation, handledRequests, handledRequestOrder);

    const handler = rpcHandlers.get(rpcKey(envelope.module, envelope.name));
    if (!handler) {
      await post({
        ...rpcResponseEnvelope(
          envelope.module,
          envelope.name,
          envelope.requestId
        ),
        kind: 'rpc.error',
        error: {code: 'NO_HANDLER', message: 'No RPC handler registered'},
      });
      return;
    }

    try {
      const response = await handler(cloneValue(envelope.payload) as never);
      if (disposed) return;
      if (!endpoint.response(response)) {
        throw new NuiRuntimeError(
          'invalid_response',
          `Invalid response for ${envelope.module}.${envelope.name}`,
          response
        );
      }
      await post({
        ...rpcResponseEnvelope(
          envelope.module,
          envelope.name,
          envelope.requestId
        ),
        kind: 'rpc.response',
        payload: response,
      });
    } catch (error) {
      if (disposed) return;
      await post({
        ...rpcResponseEnvelope(
          envelope.module,
          envelope.name,
          envelope.requestId
        ),
        kind: 'rpc.error',
        error: {
          code: 'HANDLER_FAILED',
          message: boundedErrorMessage(error),
        },
      });
    }
  };

  const receive = (envelope: NuiEnvelope<string>): boolean => {
    if (disposed) return false;
    if (
      envelope.module === 'core' &&
      envelope.kind === 'event' &&
      envelope.name === 'synced'
    ) {
      if (envelope.sessionId !== sessionId) return false;
      synced = true;
      if (syncedTimer !== undefined) window.clearTimeout(syncedTimer);
      resolveSynced?.();
      resolveSynced = undefined;
      rejectSynced = undefined;
      syncedTimer = undefined;
      return true;
    }
    const module = modules[envelope.module];
    if (!module) return invalidEnvelope(envelope, reportError);
    if (envelope.kind === 'state.snapshot') {
      return receiveState(module, envelope);
    }
    if (envelope.kind === 'event') return receiveEvent(module, envelope);
    if (envelope.kind === 'rpc.request') {
      void receiveRpc(module, envelope).catch(error =>
        reportError(
          normalizeRuntimeError(
            error,
            'rpc_failed',
            `Failed to deliver ${envelope.module}.${envelope.name} response`
          )
        )
      );
      return true;
    }
    return invalidEnvelope(envelope, reportError);
  };

  const nextRequestId = () => {
    requestCounter += 1;
    return `${sessionId}-nui-${requestCounter}`;
  };

  const callRpc = async (
    moduleName: string,
    name: string,
    endpoint: CompiledRpc,
    payload: unknown
  ) => {
    assertActive();
    if (!endpoint.request(payload)) {
      throw new NuiRuntimeError(
        'invalid_payload',
        `Invalid request payload for ${moduleName}.${name}`,
        payload
      );
    }
    const requestId = nextRequestId();
    const timeoutMs = configuredTimeout ?? normalizeTimeout(
      endpoint.contract.timeoutMs ?? NUI_RPC_TIMEOUT_MS
    );
    const mockHandler = browserMockHandler(options, moduleName, name);
    try {
      const response = mockHandler
        ? await dispatchMockRpc(
            moduleName,
            name,
            requestId,
            cloneValue(payload),
            mockHandler,
            timeoutMs,
            pendingControllers
          )
        : await postEnvelope(
            resourceName,
            timeoutMs,
            {
              version: NUI_VERSION,
              module: moduleName,
              kind: 'rpc.request',
              name,
              requestId,
              payload,
            },
            pendingControllers
          );
      if (
        response.version !== NUI_VERSION ||
        response.module !== moduleName ||
        response.name !== name ||
        response.requestId !== requestId
      ) {
        throw new NuiRuntimeError(
          'invalid_response',
          `Invalid response envelope for ${moduleName}.${name}`,
          response
        );
      }
      if (response.kind === 'rpc.error') {
        throw new NuiRuntimeError(
          response.error?.code ?? 'rpc_failed',
          response.error?.message ?? 'RPC failed',
          response.error
        );
      }
      if (
        response.kind !== 'rpc.response' ||
        !endpoint.response(response.payload)
      ) {
        throw new NuiRuntimeError(
          'invalid_response',
          `Invalid response payload for ${moduleName}.${name}`,
          response
        );
      }
      return cloneValue(response.payload);
    } catch (error) {
      const runtimeError = normalizeRuntimeError(
        error,
        'rpc_failed',
        `RPC failed for ${moduleName}.${name}`
      );
      reportError(runtimeError);
      throw runtimeError;
    }
  };

  const writeState = (
    moduleName: string,
    name: string,
    state: CompiledState,
    kind: 'state.set' | 'state.patch',
    payload: unknown
  ) => {
    try {
      assertActive();
    } catch (error) {
      return Promise.reject(error);
    }
    const validate = kind === 'state.set' ? state.validate : state.validatePatch;
    if (!validate?.(payload)) return Promise.resolve(false);
    const key = stateKey(moduleName, name);
    const safePayload = cloneValue(payload);
    const module = modules[moduleName]!;
    const optimistic = applyStateWrite(module.values[name], {
      kind,
      payload: safePayload,
    });
    if (!state.validate(optimistic)) return Promise.resolve(false);
    const pending: PendingWrite = {kind, payload: safePayload};
    const stateWrites = pendingWrites.get(key) ?? [];
    stateWrites.push(pending);
    pendingWrites.set(key, stateWrites);
    module.values[name] = cloneValue(optimistic);
    notify(key, optimistic);

    const perform = async () => {
      assertActive();
      const requestId = nextRequestId();
      const request: NuiEnvelope<string> = {
        version: NUI_VERSION,
        module: moduleName,
        kind,
        name,
        requestId,
        sessionId,
        payload: safePayload,
      };
      const response = options.browserMock
        ? await dispatchMockState(
            {
              module: moduleName,
              name,
              kind,
              requestId,
              sessionId,
              payload: cloneValue(safePayload),
              current: cloneValue(module.canonical[name]),
              next: cloneValue(applyStateWrite(module.canonical[name], pending)),
            },
            options.browserMock.writeState ?? (mockRequest => {
              const revision = Math.max(
                mockRevisions.get(key) ?? 1,
                revisions.get(key) ?? 0
              ) + 1;
              mockRevisions.set(key, revision);
              return {payload: mockRequest.next, revision};
            }),
            configuredTimeout ?? NUI_RPC_TIMEOUT_MS,
            pendingControllers
          )
        : await post(request);
      assertActive();
      if (
        response.version !== NUI_VERSION ||
        response.module !== moduleName ||
        response.name !== name ||
        response.requestId !== requestId ||
        response.sessionId !== sessionId
      ) {
        throw new NuiRuntimeError(
          'invalid_response',
          `Invalid acknowledgement for ${moduleName}.${name}`,
          response
        );
      }
      if (response.kind === 'rpc.error') {
        throw new NuiRuntimeError(
          response.error?.code ?? 'rpc_failed',
          response.error?.message ?? `State write failed for ${moduleName}.${name}`,
          response.error
        );
      }
      if (
        response.kind !== 'rpc.response' ||
        !isPositiveInteger(response.revision) ||
        !state.validate(response.payload)
      ) {
        throw new NuiRuntimeError(
          'invalid_response',
          `Invalid acknowledgement for ${moduleName}.${name}`,
          response
        );
      }
      removePendingWrite(key, pendingWrites, pending);
      if (response.revision > (revisions.get(key) ?? 0)) {
        revisions.set(key, response.revision);
        module.canonical[name] = cloneValue(response.payload);
      }
      refreshEffectiveValue(module, name, key);
      return true;
    };
    const previous = writeQueues.get(key) ?? Promise.resolve();
    const operation = previous.then(perform, perform);
    const settled = operation.then(
      () => undefined,
      () => undefined
    );
    writeQueues.set(key, settled);
    void settled.then(() => {
      if (writeQueues.get(key) === settled) writeQueues.delete(key);
    });
    return operation.catch(error => {
      removePendingWrite(key, pendingWrites, pending);
      if (!disposed) refreshEffectiveValue(module, name, key);
      const runtimeError = normalizeRuntimeError(
        error,
        'rpc_failed',
        `Failed to write ${moduleName}.${name}`
      );
      reportError(runtimeError);
      throw runtimeError;
    });
  };

  const facades = buildFacades({
    modules,
    subscribe,
    callRpc,
    writeState,
    post,
    rpcHandlers,
    rpcKey,
    assertActive,
    reportError,
  });

  const windowListener = (event: MessageEvent<unknown>) => {
    // FiveM hosts fullscreen NUI as an iframe and dispatches messages from its parent.
    if (
      event.source !== null &&
      event.source !== window &&
      event.source !== window.parent
    ) {
      return;
    }
    if (!isWithinPayloadLimit(event.data)) {
      reportError(
        new NuiRuntimeError('invalid_envelope', 'NUI envelope is too large')
      );
      return;
    }
    const parsed = parseEnvelope(event.data);
    if (!parsed) {
      reportError(
        new NuiRuntimeError(
          'invalid_envelope',
          'Invalid canonical NUI envelope',
          event.data
        )
      );
      return;
    }
    receive(parsed);
  };
  window.addEventListener('message', windowListener);

  return {
    nui: facades as GeneratedNuiModules<Contracts>,
    sessionId,
    ready() {
      try {
        assertActive();
      } catch (error) {
        return Promise.reject(error);
      }
      if (readyPromise) return readyPromise;

      const operation = (async () => {
        const envelope: NuiEnvelope<'core'> = {
          version: NUI_VERSION,
          module: 'core',
          kind: 'event',
          name: 'ready',
          sessionId,
          payload: {sessionId},
        };
        if (options.browserMock) return true;
        try {
          const response = await post(envelope);
          if (
            response.version !== NUI_VERSION ||
            response.module !== 'core' ||
            response.name !== 'ready' ||
            response.sessionId !== sessionId
          ) {
            throw new NuiRuntimeError(
              'invalid_response',
              'Invalid acknowledgement for core.ready',
              response
            );
          }
          if (response.kind === 'rpc.error') {
            throw new NuiRuntimeError(
              response.error?.code ?? 'rpc_failed',
              response.error?.message ?? 'NUI ready handshake failed',
              response.error
            );
          }
          if (response.kind !== 'rpc.response') {
            throw new NuiRuntimeError(
              'invalid_response',
              'Invalid acknowledgement for core.ready',
              response
            );
          }
          if (!synced) {
            await new Promise<void>((resolve, reject) => {
              resolveSynced = resolve;
              rejectSynced = reject;
              syncedTimer = window.setTimeout(() => {
                if (resolveSynced !== resolve) return;
                resolveSynced = undefined;
                rejectSynced = undefined;
                syncedTimer = undefined;
                reject(
                  new NuiRuntimeError(
                    'timeout',
                    'Timed out waiting for core.synced'
                  )
                );
              }, configuredTimeout ?? NUI_RPC_TIMEOUT_MS);
              void Promise.resolve().then(() => {
                if (!synced) return;
                if (syncedTimer !== undefined) window.clearTimeout(syncedTimer);
                resolveSynced = undefined;
                rejectSynced = undefined;
                syncedTimer = undefined;
                resolve();
              });
            });
          }
          return true;
        } catch (error) {
          const runtimeError = normalizeRuntimeError(
            error,
            'rpc_failed',
            'NUI ready handshake failed'
          );
          reportError(runtimeError);
          throw runtimeError;
        }
      })();
      readyPromise = operation;
      void operation.catch(() => {
        if (readyPromise === operation) readyPromise = undefined;
      });
      return operation;
    },
    async startBrowserMock() {
      assertActive();
      await options.browserMock?.boot?.(envelope =>
        receive(
          envelope.kind === 'state.snapshot'
            ? {...envelope, sessionId: envelope.sessionId ?? sessionId}
            : envelope
        )
      );
    },
    dispose() {
      if (disposed) return;
      disposed = true;
      pendingControllers.forEach(controller =>
        controller.abort(
          new NuiRuntimeError('disposed', 'NUI runtime is disposed')
        )
      );
      pendingControllers.clear();
      if (syncedTimer !== undefined) window.clearTimeout(syncedTimer);
      rejectSynced?.(
        new NuiRuntimeError('disposed', 'NUI runtime is disposed')
      );
      subscribers.clear();
      rpcHandlers.clear();
      revisions.clear();
      writeQueues.clear();
      pendingWrites.clear();
      mockRevisions.clear();
      handledRequests.clear();
      handledRequestOrder.length = 0;
      notificationQueue.length = 0;
      notifying = false;
      readyPromise = undefined;
      resolveSynced = undefined;
      rejectSynced = undefined;
      syncedTimer = undefined;
      window.removeEventListener('message', windowListener);
    },
  };
}

interface FacadeContext {
  modules: Record<string, CompiledModule>;
  subscribe(key: string, listener: Listener): NuiSubscription;
  callRpc(
    moduleName: string,
    name: string,
    endpoint: CompiledRpc,
    payload: unknown
  ): Promise<unknown>;
  writeState(
    moduleName: string,
    name: string,
    state: CompiledState,
    kind: 'state.set' | 'state.patch',
    payload: unknown
  ): Promise<boolean>;
  post(envelope: NuiEnvelope<string>): Promise<NuiEnvelope<string>>;
  rpcHandlers: Map<string, RpcHandler>;
  rpcKey(module: string, name: string): string;
  assertActive(): void;
  reportError(error: NuiRuntimeError): void;
}

function buildFacades(context: FacadeContext) {
  const facades: Record<string, unknown> = {};
  for (const [moduleName, module] of Object.entries(context.modules)) {
    const state: Record<string, unknown> = {};
    const events: Record<string, unknown> = {};
    const rpc: Record<string, unknown> = {};

    for (const [name, compiled] of Object.entries(module.state)) {
      const key = `${moduleName}:state:${name}`;
      const reader = {
        get: () => {
          context.assertActive();
          return cloneValue(module.values[name]);
        },
        subscribe: (listener: Listener) => context.subscribe(key, listener),
      };
      state[name] = {
        ...reader,
        set: (payload: unknown) =>
          context.writeState(
            moduleName,
            name,
            compiled,
            'state.set',
            payload
          ),
        ...(compiled.validatePatch
          ? {
              patch: (payload: unknown) =>
                context.writeState(
                  moduleName,
                  name,
                  compiled,
                  'state.patch',
                  payload
                ),
            }
          : {}),
      };
    }

    for (const name of Object.keys(module.eventsToNui)) {
      events[name] = {
        subscribe: (listener: Listener) =>
          context.subscribe(`${moduleName}:event:${name}`, listener),
      };
    }
    for (const [name, validate] of Object.entries(module.eventsToClient)) {
      events[name] = {
        emit: async (payload: unknown) => {
          if (!validate(payload)) return false;
          try {
            const response = await context.post({
              version: NUI_VERSION,
              module: moduleName,
              kind: 'event',
              name,
              payload,
            });
            return (
              response.version === NUI_VERSION &&
              response.module === moduleName &&
              response.name === name &&
              response.kind === 'rpc.response'
            );
          } catch (error) {
            const runtimeError = normalizeRuntimeError(
              error,
              'rpc_failed',
              `Failed to emit ${moduleName}.${name}`
            );
            context.reportError(runtimeError);
            throw runtimeError;
          }
        },
      };
    }

    for (const [name, endpoint] of Object.entries(module.rpcToClient)) {
      rpc[name] = {
        call: (payload: unknown) =>
          context.callRpc(moduleName, name, endpoint, payload),
      };
    }
    for (const name of Object.keys(module.rpcToNui)) {
      rpc[name] = {
        handle: (handler: RpcHandler) => {
          context.assertActive();
          const key = context.rpcKey(moduleName, name);
          if (context.rpcHandlers.has(key)) {
            throw new NuiRuntimeError(
              'invalid_envelope',
              `A handler for ${moduleName}.${name} is already registered`
            );
          }
          context.rpcHandlers.set(key, handler);
          let active = true;
          return {
            dispose() {
              if (!active) return;
              active = false;
              if (context.rpcHandlers.get(key) === handler) {
                context.rpcHandlers.delete(key);
              }
            },
          };
        },
      };
    }
    facades[moduleName] = {state, events, rpc};
  }
  return facades;
}

function compileModules(contracts: ContractRegistry) {
  const modules: Record<string, CompiledModule> = {};
  for (const [moduleName, contract] of Object.entries(contracts)) {
    if (moduleName !== contract.id) {
      throw new NuiRuntimeError(
        'invalid_envelope',
        `Contract registry key ${moduleName} does not match ${contract.id}`
      );
    }
    const state: Record<string, CompiledState> = {};
    const canonical: Record<string, unknown> = {};
    const values: Record<string, unknown> = {};
    for (const [name, item] of Object.entries(contract.state)) {
      state[name] = {
        contract: item,
        validate: validator(item.schema),
        ...(item.patch ? {validatePatch: validator(item.patch)} : {}),
      };
      canonical[name] = cloneValue(item.default);
      values[name] = cloneValue(item.default);
    }
    modules[moduleName] = {
      contract,
      state,
      canonical,
      values,
      eventsToNui: compileSchemaMap(contract.nui.events.toNui),
      eventsToClient: compileSchemaMap(contract.nui.events.toClient),
      rpcToNui: compileRpcMap(contract.nui.rpc.toNui),
      rpcToClient: compileRpcMap(contract.nui.rpc.toClient),
    };
  }
  return modules;
}

function compileSchemaMap(schemas: Readonly<Record<string, ContractSchema>>) {
  return Object.fromEntries(
    Object.entries(schemas).map(([name, schema]) => [name, validator(schema)])
  );
}

function compileRpcMap(endpoints: Readonly<Record<string, RpcContract>>) {
  return Object.fromEntries(
    Object.entries(endpoints).map(([name, endpoint]) => [
      name,
      {
        contract: endpoint,
        request: validator(endpoint.request),
        response: validator(endpoint.response),
      },
    ])
  ) as Record<string, CompiledRpc>;
}

function validator(schema: ContractSchema): Validator {
  return compileValidator(schema);
}

function invalidEnvelope(
  envelope: NuiEnvelope<string>,
  reportError: (error: NuiRuntimeError) => void
) {
  reportError(
    new NuiRuntimeError('invalid_envelope', 'Unsupported NUI envelope', envelope)
  );
  return false;
}

function rememberRequest(
  correlation: string,
  handled: Set<string>,
  order: string[]
) {
  handled.add(correlation);
  order.push(correlation);
  if (order.length > 1024) {
    const expired = order.shift();
    if (expired) handled.delete(expired);
  }
}

function browserMockHandler<Contracts extends ContractRegistry>(
  options: NuiRuntimeOptions<Contracts>,
  module: string,
  name: string
): ((payload: unknown) => Promise<unknown> | unknown) | undefined {
  const rpc = options.browserMock?.rpc as
    | Record<
        string,
        Record<string, (payload: unknown) => Promise<unknown> | unknown>
      >
    | undefined;
  return rpc?.[module]?.[name];
}

function isObject(value: unknown): value is Record<string, unknown> {
  return value !== null && typeof value === 'object' && !Array.isArray(value);
}

function applyStateWrite(current: unknown, write: PendingWrite) {
  if (write.kind === 'state.set') return cloneValue(write.payload);
  if (!isObject(current) || !isObject(write.payload)) return undefined;
  return {...current, ...cloneValue(write.payload)};
}

function removePendingWrite(
  key: string,
  pendingWrites: Map<string, PendingWrite[]>,
  pending: PendingWrite
) {
  const writes = pendingWrites.get(key);
  if (!writes) return;
  const index = writes.indexOf(pending);
  if (index >= 0) writes.splice(index, 1);
  if (writes.length === 0) pendingWrites.delete(key);
}

function boundedErrorMessage(error: unknown) {
  const message = error instanceof Error ? error.message : 'RPC handler failed';
  return message.slice(0, 512);
}
