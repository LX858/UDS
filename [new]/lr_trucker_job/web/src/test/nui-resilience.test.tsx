import {cleanup, waitFor} from '@testing-library/react';
import {afterEach, describe, expect, it, vi} from 'vitest';
import {
  type ContractSchema,
  defineModuleContract,
  defineStateContract,
  rpc,
} from '@lr/contracts';
import {createAppRuntime} from '../app/runtime';
import {bindStores} from '../app/storeRuntime';
import {NUI_VERSION} from '../nui/contracts';
import {
  createNuiRuntime as createGeneratedNuiRuntime,
  type NuiEnvelope,
  NuiRuntimeError,
} from '../nui/runtime';
import {
  createFixtureNuiRuntime as createNuiRuntime,
  fixtureContract,
  FixtureStore,
} from './nui.fixture';

describe('NUI runtime resilience', () => {
  afterEach(() => {
    cleanup();
    vi.restoreAllMocks();
    vi.unstubAllGlobals();
  });

  it('isolates a failing subscriber and continues notification', () => {
    const errors: NuiRuntimeError[] = [];
    const runtime = createNuiRuntime({onError: error => errors.push(error)});
    const healthy = vi.fn();
    runtime.nui.fixture.state.visibility.subscribe(() => {
      throw new Error('subscriber failed');
    });
    runtime.nui.fixture.state.visibility.subscribe(healthy);

    dispatchState(runtime, 'visibility', 2, {visible: true});

    expect(healthy).toHaveBeenCalledWith({visible: true});
    expect(errors).toHaveLength(1);
    expect(errors[0]?.code).toBe('subscriber_failed');
    runtime.dispose();
  });

  it('delivers reentrant state notifications in FIFO order', async () => {
    const runtime = createNuiRuntime({browserMock: {}});
    const order: string[] = [];
    let nestedWrite: Promise<boolean> | undefined;
    runtime.nui.fixture.state.visibility.subscribe(value => {
      order.push(`first:${value.visible}`);
      if (value.visible) {
        nestedWrite = runtime.nui.fixture.state.visibility.set({visible: false});
      }
    });
    runtime.nui.fixture.state.visibility.subscribe(value => {
      order.push(`second:${value.visible}`);
    });

    const outerWrite = runtime.nui.fixture.state.visibility.set({visible: true});

    expect(order).toEqual([
      'first:true',
      'second:true',
      'first:false',
      'second:false',
    ]);
    await expect(outerWrite).resolves.toBe(true);
    await expect(nestedWrite).resolves.toBe(true);
    runtime.dispose();
  });

  it('times out and cancels hanging browser RPC and state calls', async () => {
    const runtime = createNuiRuntime({
      timeoutMs: 5,
      browserMock: {
        rpc: {fixture: {close: () => new Promise(() => undefined)}},
        writeState: () => new Promise(() => undefined),
      },
    });

    await expect(runtime.nui.fixture.rpc.close.call({})).rejects.toMatchObject({
      code: 'timeout',
    });
    await expect(
      runtime.nui.fixture.state.preferences.set({compact: true})
    ).rejects.toMatchObject({code: 'timeout'});

    const pending = runtime.nui.fixture.state.preferences.set({compact: false});
    runtime.dispose();
    await expect(pending).rejects.toMatchObject({code: 'disposed'});
  });

  it('rolls back a rejected optimistic write and reports the definitive code', async () => {
    const errors: NuiRuntimeError[] = [];
    const runtime = createNuiRuntime({
      onError: error => errors.push(error),
      browserMock: {
        writeState: () => {
          throw new NuiRuntimeError('DENIED', 'Denied');
        },
      },
    });
    const listener = vi.fn();
    runtime.nui.fixture.state.preferences.subscribe(listener);

    const write = runtime.nui.fixture.state.preferences.set({compact: true});
    expect(runtime.nui.fixture.state.preferences.get()).toEqual({compact: true});
    await expect(write).rejects.toMatchObject({code: 'DENIED'});
    expect(runtime.nui.fixture.state.preferences.get()).toEqual({compact: false});
    expect(listener.mock.calls.map(call => call[0])).toEqual([
      {compact: true},
      {compact: false},
    ]);
    expect(errors.at(-1)?.code).toBe('DENIED');
    runtime.dispose();
  });

  it('does not apply a state completion after disposal', async () => {
    let resolveWrite: ((value: {payload: unknown; revision: number}) => void) | undefined;
    const runtime = createNuiRuntime({
      browserMock: {
        writeState: () =>
          new Promise(resolve => {
            resolveWrite = resolve;
          }),
      },
    });
    const listener = vi.fn();
    runtime.nui.fixture.state.preferences.subscribe(listener);

    const write = runtime.nui.fixture.state.preferences.set({compact: true});
    await waitFor(() => expect(resolveWrite).toBeTypeOf('function'));
    runtime.dispose();
    resolveWrite!({payload: {compact: false}, revision: 10});

    await expect(write).rejects.toMatchObject({code: 'disposed'});
    expect(listener).toHaveBeenCalledOnce();
    expect(() => runtime.nui.fixture.state.preferences.get()).toThrow(/disposed/);
  });

  it('serializes rapid decorated assignments', async () => {
    const requests: Array<{next: unknown}> = [];
    const resolvers: Array<(value: {payload: unknown; revision: number}) => void> = [];
    const runtime = createNuiRuntime({
      browserMock: {
        writeState: request => {
          requests.push(request);
          return new Promise(resolve => resolvers.push(resolve));
        },
      },
    });
    const stores = bindStores(runtime as never, {fixture: FixtureStore});
    await runtime.startBrowserMock();

    stores.stores.fixture.preferences = {compact: true};
    stores.stores.fixture.preferences = {compact: false};
    await waitFor(() => expect(requests).toHaveLength(1));
    expect(stores.stores.fixture.preferences).toEqual({compact: false});

    resolvers[0]!({payload: {compact: true}, revision: 2});
    await waitFor(() => expect(requests).toHaveLength(2));
    expect(stores.stores.fixture.preferences).toEqual({compact: false});
    resolvers[1]!({payload: {compact: false}, revision: 3});
    await stores.flush();
    expect(stores.stores.fixture.preferences).toEqual({compact: false});
    stores.dispose();
    runtime.dispose();
  });

  it('ignores canonical messages from a foreign frame', () => {
    const runtime = createNuiRuntime();
    const listener = vi.fn();
    const frame = document.createElement('iframe');
    document.body.append(frame);
    runtime.nui.fixture.state.visibility.subscribe(listener);

    window.dispatchEvent(
      new MessageEvent('message', {
        data: stateEnvelope(runtime, 'visibility', 2, {visible: true}),
        source: frame.contentWindow,
      })
    );

    expect(listener).not.toHaveBeenCalled();
    frame.remove();
    runtime.dispose();
  });

  it('rejects malformed correlation, session, revision, and error metadata', () => {
    const errors: NuiRuntimeError[] = [];
    const runtime = createNuiRuntime({onError: error => errors.push(error)});

    dispatchMessage({...stateEnvelope(runtime, 'visibility', 2, {visible: true}), sessionId: 4});
    dispatchMessage({...stateEnvelope(runtime, 'visibility', 2, {visible: true}), revision: '2'});
    dispatchMessage({
      version: NUI_VERSION,
      module: 'fixture',
      kind: 'rpc.error',
      name: 'close',
      requestId: 'x'.repeat(129),
      error: {code: 'x'.repeat(65)},
    });

    expect(errors.map(error => error.code)).toEqual([
      'invalid_envelope',
      'invalid_envelope',
      'invalid_envelope',
    ]);
    runtime.dispose();
  });

  it('rejects unknown endpoints and invalid inbound state/event payloads', () => {
    const errors: NuiRuntimeError[] = [];
    const runtime = createNuiRuntime({onError: error => errors.push(error)});

    dispatchMessage({...stateEnvelope(runtime, 'missing', 2, {}), module: 'unknown'});
    dispatchMessage(stateEnvelope(runtime, 'missing', 2, {}));
    dispatchMessage(stateEnvelope(runtime, 'visibility', 2, {visible: 'yes'}));
    dispatchMessage({
      ...stateEnvelope(runtime, 'snapshot', 2, {unknown: true}),
      kind: 'state.patch',
    });
    dispatchMessage({
      version: NUI_VERSION,
      module: 'fixture',
      kind: 'event',
      name: 'toast',
      payload: {level: 'loud', message: 'invalid'},
    });

    expect(errors.map(error => error.code)).toEqual([
      'invalid_envelope',
      'invalid_payload',
      'invalid_payload',
      'invalid_envelope',
      'invalid_payload',
    ]);
    runtime.dispose();
  });

  it('normalizes HTTP, JSON, oversized, and malformed bridge responses', async () => {
    const fetchSpy = vi.fn();
    vi.stubGlobal('fetch', fetchSpy);

    fetchSpy.mockResolvedValueOnce(new Response('{}', {status: 500}));
    const http = createNuiRuntime({resourceName: 'test_resource'});
    await expect(http.nui.fixture.rpc.close.call({})).rejects.toMatchObject({
      code: 'rpc_failed',
    });
    http.dispose();

    fetchSpy.mockResolvedValueOnce(new Response('not-json', {status: 200}));
    const json = createNuiRuntime({resourceName: 'test_resource'});
    await expect(json.nui.fixture.rpc.close.call({})).rejects.toMatchObject({
      code: 'invalid_response',
    });
    json.dispose();

    fetchSpy.mockResolvedValueOnce(
      new Response(JSON.stringify('x'.repeat(300 * 1024)), {status: 200})
    );
    const oversized = createNuiRuntime({resourceName: 'test_resource'});
    await expect(oversized.nui.fixture.rpc.close.call({})).rejects.toMatchObject({
      code: 'invalid_response',
    });
    oversized.dispose();

    fetchSpy.mockResolvedValueOnce(
      new Response(JSON.stringify({version: NUI_VERSION, module: 'fixture'}), {
        status: 200,
      })
    );
    const malformed = createNuiRuntime({resourceName: 'test_resource'});
    await expect(malformed.nui.fixture.rpc.close.call({})).rejects.toMatchObject({
      code: 'invalid_response',
    });
    malformed.dispose();
  });

  it('rejects invalid writes and invalid ready acknowledgements', async () => {
    const runtime = createNuiRuntime({browserMock: {}});
    await expect(
      runtime.nui.fixture.state.visibility.set({visible: 'yes'} as never)
    ).resolves.toBe(false);
    await expect(
      runtime.nui.fixture.state.snapshot.patch({unknown: true} as never)
    ).resolves.toBe(false);
    runtime.dispose();

    vi.stubGlobal(
      'fetch',
      vi.fn(async () =>
        bridgeResponse({
          version: NUI_VERSION,
          module: 'core',
          kind: 'rpc.error',
          name: 'ready',
          sessionId: 'wrong-session',
          error: {code: 'DENIED'},
        })
      )
    );
    const ready = createNuiRuntime({resourceName: 'test_resource'});
    await expect(ready.ready()).rejects.toMatchObject({code: 'invalid_response'});
    ready.dispose();
  });

  it('reports startup failures, permits retry, and resolves only after synced', async () => {
    const errors: NuiRuntimeError[] = [];
    const fetchSpy = vi.fn();
    fetchSpy.mockResolvedValueOnce(
      new Response('not-json', {status: 200, headers: {'Content-Type': 'text/plain'}})
    );
    fetchSpy.mockImplementationOnce(async (_url: RequestInfo, init?: RequestInit) => {
      const request = JSON.parse(String(init?.body)) as NuiEnvelope;
      const sessionId = request.sessionId;
      if (!sessionId) throw new Error('ready request is missing sessionId');
      window.setTimeout(
        () =>
          dispatchMessage({
            version: NUI_VERSION,
            module: 'core',
            kind: 'event',
            name: 'synced',
            sessionId,
            payload: {sessionId},
          }),
        0
      );
      return bridgeResponse({
        version: NUI_VERSION,
        module: 'core',
        kind: 'rpc.response',
        name: 'ready',
        sessionId,
        payload: {sessionId},
      });
    });
    vi.stubGlobal('fetch', fetchSpy);
    const runtime = createAppRuntime({
      isBrowser: false,
      resourceName: 'test_resource',
      onError: error => errors.push(error),
    });

    await expect(runtime.start()).rejects.toMatchObject({code: 'invalid_response'});
    await expect(runtime.start()).resolves.toBeUndefined();
    expect(errors.at(-1)?.code).toBe('invalid_response');
    expect(fetchSpy).toHaveBeenCalledTimes(2);
    runtime.dispose();
  });

  it('shares one in-flight ready handshake across concurrent callers', async () => {
    let readyRequest: NuiEnvelope | undefined;
    const fetchSpy = vi.fn(async (_url: RequestInfo, init?: RequestInit) => {
      readyRequest = JSON.parse(String(init?.body)) as NuiEnvelope;
      const requestSessionId = readyRequest.sessionId;
      if (!requestSessionId) throw new Error('ready request is missing sessionId');
      return bridgeResponse({
        version: NUI_VERSION,
        module: 'core',
        kind: 'rpc.response',
        name: 'ready',
        sessionId: requestSessionId,
        payload: {sessionId: requestSessionId},
      });
    });
    vi.stubGlobal('fetch', fetchSpy);
    const runtime = createNuiRuntime({resourceName: 'test_resource'});

    const first = runtime.ready();
    const second = runtime.ready();
    expect(second).toBe(first);
    await waitFor(() => expect(readyRequest).toBeDefined());
    dispatchMessage({
      version: NUI_VERSION,
      module: 'core',
      kind: 'event',
      name: 'synced',
      sessionId: runtime.sessionId,
      payload: {sessionId: runtime.sessionId},
    });

    await expect(Promise.all([first, second])).resolves.toEqual([true, true]);
    expect(fetchSpy).toHaveBeenCalledOnce();
    runtime.dispose();
  });

  it('builds writable facades and browser state emulation for every module', async () => {
    const inventory = defineModuleContract({
      id: 'inventory',
      state: {
        items: defineStateContract(
          schema({type: 'array', items: {type: 'string'}}),
          []
        ),
      },
      nui: {
        events: {toNui: {refreshed: schema({type: 'object'})}, toClient: {}},
        rpc: {
          toNui: {},
          toClient: {
            ping: rpc(
              schema({type: 'object'}),
              schema({
                type: 'object',
                required: ['ok'],
                properties: {ok: {type: 'boolean'}},
              })
            ),
          },
        },
      },
      net: {
        events: {clientToServer: {}, serverToClient: {}},
        rpc: {clientToServer: {}, serverToClient: {}},
      },
      exports: {client: {}, server: {}},
    });
    const runtime = createGeneratedNuiRuntime({
      contracts: {fixture: fixtureContract, inventory},
      browserMock: {rpc: {inventory: {ping: () => ({ok: true})}}},
    });

    dispatchMessage({
      version: NUI_VERSION,
      module: 'inventory',
      kind: 'state.snapshot',
      name: 'items',
      sessionId: runtime.sessionId,
      revision: 2,
      payload: ['water'],
    });
    expect(runtime.nui.inventory.state.items.get()).toEqual(['water']);
    await expect(runtime.nui.inventory.state.items.set(['bread'])).resolves.toBe(true);
    expect(runtime.nui.inventory.state.items.get()).toEqual(['bread']);
    await expect(runtime.nui.inventory.rpc.ping.call({})).resolves.toEqual({ok: true});
    runtime.dispose();
  });

  it('validates store registries and reports rejected bound writes', async () => {
    const runtime = createNuiRuntime({browserMock: {}});
    expect(() =>
      bindStores(runtime as never, {wrong: FixtureStore} as never)
    ).toThrow(/registry key/i);
    expect(() =>
      bindStores({nui: {}} as never, {fixture: FixtureStore})
    ).toThrow(/generated NUI facade/i);
    expect(() =>
      bindStores(
        {nui: {fixture: {state: {}}}} as never,
        {fixture: FixtureStore}
      )
    ).toThrow(/generated state facade/i);

    const errors: NuiRuntimeError[] = [];
    runtime.nui.fixture.state.preferences.set = vi.fn(async () => false);
    const stores = bindStores(
      runtime as never,
      {fixture: FixtureStore},
      error => errors.push(error)
    );
    stores.stores.fixture.preferences = {compact: true};
    await stores.flush();
    expect(errors.at(-1)).toMatchObject({code: 'invalid_payload'});
    expect(stores.stores.fixture.L('missing')).toBe('missing');
    stores.dispose();
    runtime.dispose();
  });
});

function stateEnvelope(
  runtime: ReturnType<typeof createNuiRuntime>,
  name: string,
  revision: number,
  payload: unknown
): NuiEnvelope<'fixture'> {
  return {
    version: NUI_VERSION,
    module: 'fixture',
    kind: 'state.snapshot',
    name,
    sessionId: runtime.sessionId,
    revision,
    payload,
  };
}

function dispatchState(
  runtime: ReturnType<typeof createNuiRuntime>,
  name: string,
  revision: number,
  payload: unknown
) {
  dispatchMessage(stateEnvelope(runtime, name, revision, payload));
}

function bridgeResponse(envelope: NuiEnvelope) {
  return new Response(JSON.stringify(envelope), {
    status: 200,
    headers: {'Content-Type': 'application/json'},
  });
}

function dispatchMessage(data: unknown) {
  window.dispatchEvent(new MessageEvent('message', {data}));
}

function schema(value: ContractSchema): ContractSchema {
  return value;
}
