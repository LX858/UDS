import {
  createNuiRuntime,
  NuiBrowserMock,
  NuiRuntime,
  NuiRuntimeError,
} from '../nui/runtime';
import {isEnvBrowser} from '../utils/misc';
import {createDefaultBrowserMock} from './browser.mock';
import {storeModules} from './modules/registry';
import {bindStores, type StoreInstances} from './storeRuntime';

export interface AppRuntimeOptions {
  resourceName?: string;
  isBrowser?: boolean;
  browserMock?: NuiBrowserMock;
  onError?: (error: NuiRuntimeError) => void;
}

export class AppRuntime {
  readonly nui: NuiRuntime;
  readonly stores: StoreInstances<typeof storeModules>;
  readonly isBrowser: boolean;
  private readonly storeRuntime;
  private started = false;
  private disposed = false;

  constructor(options: AppRuntimeOptions = {}) {
    const browser = options.isBrowser ?? isEnvBrowser();
    this.isBrowser = browser;
    const browserMock =
      options.browserMock ?? (browser ? createDefaultBrowserMock() : undefined);
    this.nui = createNuiRuntime({
      resourceName: options.resourceName ?? getParentResourceName(),
      ...(browserMock ? {browserMock} : {}),
      ...(options.onError ? {onError: options.onError} : {}),
    });
    this.storeRuntime = bindStores(this.nui, storeModules, options.onError);
    this.stores = this.storeRuntime.stores;
  }

  async start() {
    if (this.started) return;
    this.started = true;
    try {
      await this.nui.startBrowserMock();
      const ready = await this.nui.ready();
      if (!ready) {
        throw new NuiRuntimeError('invalid_response', 'NUI ready handshake was rejected');
      }
    } catch (error) {
      this.started = false;
      const runtimeError =
        error instanceof NuiRuntimeError
          ? error
          : new NuiRuntimeError('rpc_failed', 'NUI runtime startup failed', error);
      throw runtimeError;
    }
  }

  async close() {
    await this.nui.nui.trucker.rpc.close.call({});
    this.stores.trucker.visibility = {visible: false};
  }

  flush() {
    return this.storeRuntime.flush();
  }

  get storeStatus() {
    return this.storeRuntime.status;
  }

  dispose() {
    if (this.disposed) return;
    this.disposed = true;
    this.storeRuntime.dispose();
    this.nui.dispose();
  }
}

export function createAppRuntime(options?: AppRuntimeOptions) {
  return new AppRuntime(options);
}

function getParentResourceName() {
  const candidate = (window as {GetParentResourceName?: () => string})
    .GetParentResourceName;
  return candidate ? candidate() : 'nui-frame-app';
}
