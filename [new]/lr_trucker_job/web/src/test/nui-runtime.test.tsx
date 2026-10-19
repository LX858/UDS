import {act, cleanup, render, screen, waitFor} from '@testing-library/react';
import {afterEach, describe, expect, it, vi} from 'vitest';
import App from '../App';
import {createAppRuntime} from '../app/runtime';
import {AppRuntimeProvider, useAppRuntime} from '../app/runtimeContext';
import {bindStores} from '../app/storeRuntime';
import {LR_BRIDGE_ENDPOINT, NUI_VERSION} from '../nui/contracts';
import {type NuiEnvelope, NuiRuntimeError} from '../nui/runtime';
import {
  createFixtureNuiRuntime as createNuiRuntime,
  FixtureStore,
} from './nui.fixture';

describe('protocol v2 NUI runtime', () => {
  afterEach(() => {
    cleanup();
    vi.restoreAllMocks();
    vi.unstubAllGlobals();
    vi.useRealTimers();
  });

  it('rejects legacy messages and invalid sessions', () => {
    const errors: NuiRuntimeError[] = [];
    const runtime = createNuiRuntime({onError: error => errors.push(error)});
    const listener = vi.fn();
    runtime.nui.fixture.state.visibility.subscribe(listener);

    dispatchMessage({action: 'main:setShow', data: true});
    dispatchMessage({
      version: NUI_VERSION,
      module: 'fixture',
      kind: 'state.snapshot',
      name: 'visibility',
      sessionId: 'stale-session',
      revision: 1,
      payload: {visible: true},
    });

    expect(listener).not.toHaveBeenCalled();
    expect(errors.map(error => error.code)).toEqual([
      'invalid_envelope',
      'invalid_payload',
    ]);
    runtime.dispose();
  });

  it('uses one revision stream for canonical snapshots and stale updates', () => {
    const runtime = createNuiRuntime();
    const listener = vi.fn();
    runtime.nui.fixture.state.snapshot.subscribe(listener);

    dispatchState(runtime, 'snapshot', 'state.snapshot', 2, {
      count: 2,
      message: 'two',
    });
    dispatchState(runtime, 'snapshot', 'state.snapshot', 1, {
      count: 1,
      message: 'stale',
    });
    dispatchState(runtime, 'snapshot', 'state.snapshot', 3, {
      count: 2,
      message: 'three',
    });

    expect(listener.mock.calls.map(call => call[0])).toEqual([
      {count: 2, message: 'two'},
      {count: 2, message: 'three'},
    ]);
    expect(runtime.nui.fixture.state.snapshot.get()).toEqual({
      count: 2,
      message: 'three',
    });
    runtime.dispose();
  });

  it('exposes writes for every state and patch only for objects', () => {
    const runtime = createNuiRuntime();

    expect(runtime.nui.fixture.state.visibility).toEqual(
      expect.objectContaining({
        get: expect.any(Function),
        set: expect.any(Function),
        patch: expect.any(Function),
        subscribe: expect.any(Function),
      })
    );
    expect(runtime.nui.fixture.state.snapshot).toEqual(
      expect.objectContaining({set: expect.any(Function), patch: expect.any(Function)})
    );
    runtime.dispose();
  });

  it('optimistically writes without a revision and applies the canonical ACK', async () => {
    let request: NuiEnvelope | undefined;
    vi.stubGlobal(
      'fetch',
      vi.fn(async (_url: RequestInfo, init?: RequestInit) => {
        request = JSON.parse(String(init?.body)) as NuiEnvelope;
        return bridgeResponse(stateAck(request, 3, {compact: false}));
      })
    );
    const runtime = createNuiRuntime({resourceName: 'test_resource'});
    const listener = vi.fn();
    runtime.nui.fixture.state.preferences.subscribe(listener);

    const write = runtime.nui.fixture.state.preferences.set({compact: true});
    expect(runtime.nui.fixture.state.preferences.get()).toEqual({compact: true});
    await expect(write).resolves.toBe(true);

    expect(request).toMatchObject({
      version: NUI_VERSION,
      module: 'fixture',
      kind: 'state.set',
      name: 'preferences',
      requestId: expect.any(String),
      sessionId: runtime.sessionId,
      payload: {compact: true},
    });
    expect(request).not.toHaveProperty('revision');
    expect(runtime.nui.fixture.state.preferences.get()).toEqual({compact: false});
    expect(listener.mock.calls.map(call => call[0])).toEqual([
      {compact: true},
      {compact: false},
    ]);
    runtime.dispose();
  });

  it('serializes writes and ignores an ACK older than a window snapshot', async () => {
    const requests: NuiEnvelope[] = [];
    const resolvers: Array<(response: Response) => void> = [];
    vi.stubGlobal(
      'fetch',
      vi.fn(async (_url: RequestInfo, init?: RequestInit) => {
        requests.push(JSON.parse(String(init?.body)) as NuiEnvelope);
        return new Promise<Response>(resolve => resolvers.push(resolve));
      })
    );
    const runtime = createNuiRuntime({resourceName: 'test_resource'});

    const first = runtime.nui.fixture.state.preferences.set({compact: true});
    const second = runtime.nui.fixture.state.preferences.set({compact: false});
    expect(runtime.nui.fixture.state.preferences.get()).toEqual({compact: false});
    await waitFor(() => expect(requests).toHaveLength(1));

    resolvers[0]!(bridgeResponse(stateAck(requests[0]!, 2, {compact: true})));
    await expect(first).resolves.toBe(true);
    await waitFor(() => expect(requests).toHaveLength(2));
    expect(requests.map(item => item.kind)).toEqual(['state.set', 'state.set']);

    dispatchState(runtime, 'preferences', 'state.snapshot', 4, {compact: true});
    expect(runtime.nui.fixture.state.preferences.get()).toEqual({compact: false});
    resolvers[1]!(bridgeResponse(stateAck(requests[1]!, 3, {compact: false})));
    await expect(second).resolves.toBe(true);
    expect(runtime.nui.fixture.state.preferences.get()).toEqual({compact: true});
    runtime.dispose();
  });

  it('uses a session handshake and waits for the core synced barrier', async () => {
    let readyRequest: NuiEnvelope | undefined;
    const fetchSpy = vi.fn(async (_url: RequestInfo, init?: RequestInit) => {
      readyRequest = JSON.parse(String(init?.body)) as NuiEnvelope;
      const sessionId = readyRequest.sessionId;
      if (!sessionId) throw new Error('ready request is missing sessionId');
      window.setTimeout(() => {
        dispatchMessage({
          version: NUI_VERSION,
          module: 'core',
          kind: 'event',
          name: 'synced',
          sessionId,
          payload: {sessionId},
        });
      }, 0);
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
    const runtime = createNuiRuntime({resourceName: 'test_resource'});

    await expect(runtime.ready()).resolves.toBe(true);
    expect(fetchSpy).toHaveBeenCalledWith(
      `https://test_resource/${LR_BRIDGE_ENDPOINT}`,
      expect.any(Object)
    );
    expect(readyRequest).toMatchObject({
      kind: 'event',
      name: 'ready',
      sessionId: runtime.sessionId,
      payload: {sessionId: runtime.sessionId},
    });
    runtime.dispose();
  });

  it('preserves a structured RPC error code', async () => {
    vi.stubGlobal(
      'fetch',
      vi.fn(async (_url: RequestInfo, init?: RequestInit) => {
        const request = JSON.parse(String(init?.body)) as NuiEnvelope;
        return bridgeResponse({
          version: NUI_VERSION,
          module: request.module,
          kind: 'rpc.error',
          name: request.name,
          ...(request.requestId ? {requestId: request.requestId} : {}),
          error: {code: 'DENIED', message: 'Denied'},
        });
      })
    );
    const runtime = createNuiRuntime({resourceName: 'test_resource'});

    await expect(runtime.nui.fixture.rpc.close.call({})).rejects.toMatchObject({
      code: 'DENIED',
      message: 'Denied',
    });
    runtime.dispose();
  });

  it('routes typed events and RPC while retaining payload validation', async () => {
    const runtime = createNuiRuntime({
      browserMock: {rpc: {fixture: {increment: ({amount}) => ({count: amount, message: 'ok'})}}},
    });
    const toast = vi.fn();
    runtime.nui.fixture.events.toast.subscribe(toast);

    dispatchMessage({
      version: NUI_VERSION,
      module: 'fixture',
      kind: 'event',
      name: 'toast',
      payload: {level: 'success', message: 'Saved'},
    });

    expect(toast).toHaveBeenCalledWith({level: 'success', message: 'Saved'});
    await expect(runtime.nui.fixture.rpc.increment.call({amount: 2})).resolves.toEqual({
      count: 2,
      message: 'ok',
    });
    await expect(runtime.nui.fixture.rpc.increment.call({amount: 0})).rejects.toMatchObject({
      code: 'invalid_payload',
    });
    runtime.dispose();
  });

  it('emits typed events and rejects invalid outbound event payloads', async () => {
    const fetchSpy = vi.fn(async (_url: RequestInfo, init?: RequestInit) => {
      const request = JSON.parse(String(init?.body)) as NuiEnvelope;
      return bridgeResponse({
        version: NUI_VERSION,
        module: request.module,
        kind: 'rpc.response',
        name: request.name,
        payload: {ok: true},
      });
    });
    vi.stubGlobal('fetch', fetchSpy);
    const runtime = createNuiRuntime({resourceName: 'test_resource'});

    await expect(
      runtime.nui.fixture.events.selected.emit({id: 'item-1'})
    ).resolves.toBe(true);
    await expect(
      runtime.nui.fixture.events.selected.emit({id: ''})
    ).resolves.toBe(false);
    expect(fetchSpy).toHaveBeenCalledOnce();
    runtime.dispose();
  });

  it('handles, rejects, and disposes client-to-NUI RPC handlers', async () => {
    const posted: NuiEnvelope[] = [];
    vi.stubGlobal(
      'fetch',
      vi.fn(async (_url: RequestInfo, init?: RequestInit) => {
        const response = JSON.parse(String(init?.body)) as NuiEnvelope;
        posted.push(response);
        return bridgeResponse({...response, payload: {ok: true}});
      })
    );
    const runtime = createNuiRuntime({resourceName: 'test_resource'});

    dispatchMessage({
      version: NUI_VERSION,
      module: 'fixture',
      kind: 'rpc.request',
      name: 'confirm',
      requestId: 'missing',
      payload: {message: 'Continue?'},
    });
    await waitFor(() => expect(posted[0]?.error?.code).toBe('NO_HANDLER'));

    const subscription = runtime.nui.fixture.rpc.confirm.handle(() => ({
      accepted: true,
    }));
    expect(() =>
      runtime.nui.fixture.rpc.confirm.handle(() => ({accepted: false}))
    ).toThrow(/already registered/);
    dispatchMessage({
      version: NUI_VERSION,
      module: 'fixture',
      kind: 'rpc.request',
      name: 'confirm',
      requestId: 'success',
      payload: {message: 'Continue?'},
    });
    await waitFor(() =>
      expect(posted.some(item => item.requestId === 'success')).toBe(true)
    );
    expect(posted.find(item => item.requestId === 'success')).toMatchObject({
      kind: 'rpc.response',
      payload: {accepted: true},
    });
    subscription.dispose();

    runtime.nui.fixture.rpc.confirm.handle(
      () => ({accepted: 'invalid'}) as never
    );
    dispatchMessage({
      version: NUI_VERSION,
      module: 'fixture',
      kind: 'rpc.request',
      name: 'confirm',
      requestId: 'invalid-response',
      payload: {message: 'Continue?'},
    });
    await waitFor(() =>
      expect(
        posted.find(item => item.requestId === 'invalid-response')?.error?.code
      ).toBe('HANDLER_FAILED')
    );
    runtime.dispose();
  });

  it('rejects invalid configuration and all facade access after disposal', async () => {
    expect(() => createNuiRuntime({timeoutMs: 0})).toThrow(/timeout/i);
    const runtime = createNuiRuntime({browserMock: {}});
    runtime.dispose();
    runtime.dispose();

    expect(() => runtime.nui.fixture.state.visibility.get()).toThrow(/disposed/);
    expect(() =>
      runtime.nui.fixture.state.visibility.subscribe(() => undefined)
    ).toThrow(/disposed/);
    await expect(
      runtime.nui.fixture.state.visibility.set({visible: true})
    ).rejects.toMatchObject({code: 'disposed'});
    await expect(runtime.nui.fixture.rpc.close.call({})).rejects.toMatchObject({
      code: 'disposed',
    });
    await expect(runtime.ready()).rejects.toMatchObject({code: 'disposed'});
    await expect(runtime.startBrowserMock()).rejects.toMatchObject({code: 'disposed'});
  });

  it('uses the default browser mock for state, RPC, and close behavior', async () => {
    const runtime = createAppRuntime({isBrowser: true});

    await runtime.start();
    expect(runtime.stores.trucker.visibility).toEqual({visible: true});
    expect(runtime.stores.main.game).toEqual({
      playerName: 'Browser Player',
      playerId: 'preview',
    });
    expect(runtime.stores.trucker.L('close')).toBe('Đóng');
    await expect(
      runtime.nui.nui.trucker.rpc.refresh.call({})
    ).resolves.toEqual({success: true, message: 'Đã cập nhật'});
    await runtime.close();
    await runtime.flush();
    expect(runtime.stores.trucker.visibility).toEqual({visible: false});
    runtime.dispose();
  });
});

describe('decorated store integration', () => {
  afterEach(() => {
    cleanup();
    vi.restoreAllMocks();
    vi.unstubAllGlobals();
  });

  it('auto-binds all decorated accessors before ready and suppresses inbound echo', async () => {
    const writes = vi.fn(request => ({payload: request.next, revision: 4}));
    const runtime = createNuiRuntime({
      browserMock: {
        writeState: writes,
        boot: dispatch => {
          dispatch({
            version: NUI_VERSION,
            module: 'fixture',
            kind: 'state.snapshot',
            name: 'settings',
            revision: 2,
            payload: {locale: {welcome: 'Welcome :{name}'}, dev: true},
          });
          dispatch({
            version: NUI_VERSION,
            module: 'fixture',
            kind: 'state.snapshot',
            name: 'preferences',
            revision: 2,
            payload: {compact: true},
          });
        },
      },
    });
    const stores = bindStores(runtime as never, {fixture: FixtureStore});

    await runtime.startBrowserMock();
    expect(stores.stores.fixture.isDev).toBe(true);
    expect(stores.stores.fixture.L('welcome', {name: 'NUI'})).toBe('Welcome NUI');
    expect(stores.stores.fixture.preferences).toEqual({compact: true});
    expect(writes).not.toHaveBeenCalled();

    expect(() => {
      stores.stores.fixture.preferences = {compact: 'yes'} as never;
    }).toThrow(/invalid assignment/i);
    stores.stores.fixture.preferences = {compact: false};
    expect(stores.status).toBe('pending');
    await stores.flush();
    expect(writes).toHaveBeenCalledOnce();
    expect(stores.status).toBe('idle');
    stores.dispose();
    runtime.dispose();
  });

  it('disposes store reactions idempotently and prevents post-dispose writes', async () => {
    const writes = vi.fn(request => ({payload: request.next, revision: 2}));
    const runtime = createNuiRuntime({browserMock: {writeState: writes}});
    const stores = bindStores(runtime as never, {fixture: FixtureStore});
    await runtime.startBrowserMock();

    stores.dispose();
    stores.dispose();
    stores.stores.fixture.preferences = {compact: true};
    await stores.flush();
    expect(writes).not.toHaveBeenCalled();
    expect(stores.status).toBe('disposed');
    runtime.dispose();
  });

  it('renders synchronized visibility and closes through RPC', async () => {
    const close = vi.fn(() => ({success: true, message: ''}));
    const runtime = createAppRuntime({
      isBrowser: false,
      browserMock: {
        rpc: {trucker: {close}},
        boot: dispatch => {
          dispatch({
            version: NUI_VERSION,
            module: 'trucker',
            kind: 'state.snapshot',
            name: 'visibility',
            revision: 2,
            payload: {visible: true},
          });
          dispatch({
            version: NUI_VERSION,
            module: 'trucker',
            kind: 'state.snapshot',
            name: 'settings',
            revision: 2,
            payload: {locale: {close: 'Close'}, dev: false},
          });
        },
      },
    });

    render(
      <AppRuntimeProvider runtime={runtime}>
        <App />
      </AppRuntimeProvider>
    );
    expect(await screen.findByRole('dialog', {name: 'Trung tâm vận chuyển'})).toBeTruthy();

    await act(async () => screen.getByRole('button', {name: 'Close'}).click());
    await waitFor(() =>
      expect(screen.queryByRole('dialog', {name: 'Trung tâm vận chuyển'})).toBeNull()
    );
    expect(close).toHaveBeenCalledOnce();
    runtime.dispose();
  });

  it('guards a missing runtime provider', () => {
    function RuntimeProbe() {
      useAppRuntime();
      return null;
    }
    expect(() => render(<RuntimeProbe />)).toThrow(/AppRuntimeProvider/);
  });
});

function dispatchState(
  runtime: ReturnType<typeof createNuiRuntime>,
  name: string,
  kind: 'state.snapshot' | 'state.patch',
  revision: number,
  payload: unknown
) {
  dispatchMessage({
    version: NUI_VERSION,
    module: 'fixture',
    kind,
    name,
    sessionId: runtime.sessionId,
    revision,
    payload,
  });
}

function stateAck(request: NuiEnvelope, revision: number, payload: unknown): NuiEnvelope {
  return {
    version: NUI_VERSION,
    module: request.module,
    kind: 'rpc.response',
    name: request.name,
    ...(request.requestId ? {requestId: request.requestId} : {}),
    ...(request.sessionId ? {sessionId: request.sessionId} : {}),
    revision,
    payload,
  };
}

function dispatchMessage(data: unknown) {
  window.dispatchEvent(new MessageEvent('message', {data}));
}

function bridgeResponse(envelope: NuiEnvelope) {
  return new Response(JSON.stringify(envelope), {
    status: 200,
    headers: {'Content-Type': 'application/json'},
  });
}
