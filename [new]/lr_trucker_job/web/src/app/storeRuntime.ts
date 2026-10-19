import {getStoreMetadata} from '@lr/nui-store';
import {action, comparer, reaction, runInAction, toJS} from 'mobx';
import {
  NuiRuntimeError,
  type NuiRuntime,
  type NuiSubscription,
} from '../nui/runtime';

type StoreConstructor<Instance extends object = object> = new () => Instance;
type StoreRegistry = Readonly<Record<string, StoreConstructor>>;

export type StoreInstances<Registry extends StoreRegistry> = {
  readonly [Name in keyof Registry]: InstanceType<Registry[Name]>;
};

interface DynamicState {
  get(): unknown;
  set(value: unknown): Promise<boolean>;
  subscribe(listener: (value: unknown) => void): NuiSubscription;
}

export interface BoundStoreRuntime<Registry extends StoreRegistry> {
  readonly stores: StoreInstances<Registry>;
  readonly status: 'idle' | 'pending' | 'disposed';
  flush(): Promise<void>;
  dispose(): void;
}

export function bindStores<Registry extends StoreRegistry>(
  nuiRuntime: NuiRuntime,
  registry: Registry,
  onError?: (error: NuiRuntimeError) => void
): BoundStoreRuntime<Registry> {
  const disposers: Array<() => void> = [];
  const pending = new Set<Promise<void>>();
  const stores: Record<string, object> = {};
  let disposed = false;

  for (const [registryName, StoreModule] of Object.entries(registry)) {
    const metadata = getStoreMetadata(StoreModule);
    if (registryName !== metadata.id) {
      throw new TypeError(
        `Store registry key ${registryName} does not match ${metadata.id}`
      );
    }

    const store = new StoreModule() as Record<string, unknown>;
    const moduleFacade = (
      nuiRuntime.nui as unknown as Record<
        string,
        {state: Record<string, DynamicState>}
      >
    )[metadata.id];
    if (!moduleFacade) {
      throw new TypeError(`No generated NUI facade exists for ${metadata.id}`);
    }

    for (const {name: stateName} of metadata.states) {
      wrapAccessorAssignmentInAction(store, stateName, metadata.id);
      const state = moduleFacade.state[stateName];
      if (!state) {
        throw new TypeError(`No generated state facade exists for ${metadata.id}.${stateName}`);
      }

      let applyingCanonical = false;
      const subscription = state.subscribe(value => {
        if (disposed) return;
        applyingCanonical = true;
        try {
          runInAction(() => {
            store[stateName] = value;
          });
        } finally {
          applyingCanonical = false;
        }
      });
      disposers.push(() => subscription.dispose());

      applyingCanonical = true;
      try {
        runInAction(() => {
          store[stateName] = state.get();
        });
      } finally {
        applyingCanonical = false;
      }

      const stopReaction = reaction(
        () => store[stateName],
        value => {
          if (disposed || applyingCanonical) return;
          const write = state.set(toJS(value));
          const tracked = write
            .then(accepted => {
              if (!accepted && !disposed) {
                onError?.(
                  new NuiRuntimeError(
                    'invalid_payload',
                    `Rejected state assignment for ${metadata.id}.${stateName}`
                  )
                );
              }
            })
            .catch(() => undefined)
            .finally(() => pending.delete(tracked));
          pending.add(tracked);
        },
        {equals: comparer.structural}
      );
      disposers.push(stopReaction);
    }
    stores[registryName] = store;
  }

  return {
    stores: stores as StoreInstances<Registry>,
    get status() {
      if (disposed) return 'disposed';
      return pending.size > 0 ? 'pending' : 'idle';
    },
    async flush() {
      while (pending.size > 0) {
        await Promise.all([...pending]);
      }
    },
    dispose() {
      if (disposed) return;
      disposed = true;
      for (let index = disposers.length - 1; index >= 0; index -= 1) {
        disposers[index]!();
      }
      disposers.length = 0;
      pending.clear();
    },
  };
}

function wrapAccessorAssignmentInAction(
  store: Record<string, unknown>,
  stateName: string,
  moduleId: string
) {
  let owner: object | null = store;
  let descriptor: PropertyDescriptor | undefined;
  while (owner && !descriptor) {
    descriptor = Object.getOwnPropertyDescriptor(owner, stateName);
    owner = Object.getPrototypeOf(owner) as object | null;
  }
  if (!descriptor?.get || !descriptor.set) {
    throw new TypeError(`@State ${moduleId}.${stateName} is not an accessor`);
  }

  const get = descriptor.get;
  const set = descriptor.set;
  const assign = action(`${moduleId}.${stateName}.assign`, (value: unknown) => {
    set.call(store, value);
  });
  Object.defineProperty(store, stateName, {
    configurable: true,
    enumerable: descriptor.enumerable ?? false,
    get: () => get.call(store),
    set: assign,
  });
}
