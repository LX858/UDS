import {
  cloneContractValue,
  compileValidator,
  defineModuleContract,
  defineStateContract,
  type ContractSchema,
  type ContractStatic,
  type ModuleBoundaries,
  type ModuleContractInput,
  type StateContract,
} from '@lr/contracts';
import {observable} from 'mobx';

const symbolConstructor = Symbol as SymbolConstructor & {metadata?: symbol};
if (symbolConstructor.metadata === undefined) {
  // TypeScript emits decorator metadata only when this standard symbol exists.
  Object.defineProperty(Symbol, 'metadata', {
    value: Symbol('Symbol.metadata'),
  });
}

const STATE_DEFINITIONS = Symbol('lr.nui-store.state-definitions');
const STORE_METADATA = Symbol('lr.nui-store.store-metadata');

interface MutableStateMetadata {
  readonly name: string;
  readonly definition: Readonly<StateContract>;
}

export interface StoreStateMetadata {
  readonly name: string;
  readonly definition: Readonly<StateContract>;
}

export interface StoreMetadata {
  readonly id: string;
  readonly states: readonly StoreStateMetadata[];
}

export interface StoreOptions {
  readonly id: string;
}

export type StoreConstructor = abstract new (...args: any[]) => object;
export type StoreRegistry =
  | readonly StoreConstructor[]
  | Readonly<Record<string, StoreConstructor>>;

type MetadataRecord = Record<PropertyKey, unknown>;
type MetadataCarrier = StoreConstructor & {
  readonly [STORE_METADATA]?: StoreMetadata;
};

function requireDecoratorMetadata(
  metadata: DecoratorMetadata | undefined
): MetadataRecord {
  if (metadata === undefined) {
    throw new TypeError(
      '@lr/nui-store requires a standard decorators transform with metadata support'
    );
  }
  return metadata;
}

function ownStateMetadata(metadata: MetadataRecord): MutableStateMetadata[] {
  if (!Object.hasOwn(metadata, STATE_DEFINITIONS)) {
    Object.defineProperty(metadata, STATE_DEFINITIONS, {value: []});
  }
  return metadata[STATE_DEFINITIONS] as MutableStateMetadata[];
}

function hasInheritedStateMetadata(metadata: MetadataRecord): boolean {
  let inherited = Object.getPrototypeOf(metadata) as MetadataRecord | null;
  while (inherited !== null) {
    if (
      Object.hasOwn(inherited, STATE_DEFINITIONS) &&
      (inherited[STATE_DEFINITIONS] as readonly MutableStateMetadata[]).length > 0
    ) {
      return true;
    }
    inherited = Object.getPrototypeOf(inherited) as MetadataRecord | null;
  }
  return false;
}

function freezeSnapshot<T>(value: T): T {
  if (value !== null && typeof value === 'object' && !Object.isFrozen(value)) {
    for (const item of Object.values(value)) freezeSnapshot(item);
    Object.freeze(value);
  }
  return value;
}

export function State<const Schema extends ContractSchema>(
  schema: Schema,
  defaultValue: ContractStatic<Schema>
): <This>(
  value: ClassAccessorDecoratorTarget<This, ContractStatic<Schema>>,
  context: ClassAccessorDecoratorContext<This, ContractStatic<Schema>>
) => ClassAccessorDecoratorResult<This, ContractStatic<Schema>> {
  const definition = defineStateContract<Schema>(schema, defaultValue);
  const validate = compileValidator<Schema>(definition.schema);

  return <This>(
    value: ClassAccessorDecoratorTarget<This, ContractStatic<Schema>>,
    context: ClassAccessorDecoratorContext<This, ContractStatic<Schema>>
  ): ClassAccessorDecoratorResult<This, ContractStatic<Schema>> => {
    if (context.static) {
      throw new TypeError('@State cannot decorate a static accessor');
    }
    if (context.private) {
      throw new TypeError('@State cannot decorate a private accessor');
    }
    if (typeof context.name === 'symbol') {
      throw new TypeError('@State cannot decorate a symbol-named accessor');
    }

    const states = ownStateMetadata(requireDecoratorMetadata(context.metadata));
    if (states.some(state => state.name === context.name)) {
      throw new TypeError(`Duplicate @State accessor: ${context.name}`);
    }
    states.push({name: context.name, definition});

    type AccessorDecorator = (
      target: ClassAccessorDecoratorTarget<This, ContractStatic<Schema>>,
      decoratorContext: ClassAccessorDecoratorContext<This, ContractStatic<Schema>>
    ) => ClassAccessorDecoratorResult<This, ContractStatic<Schema>> | void;
    const observableResult = (observable.ref as unknown as AccessorDecorator)(value, context);
    const get = observableResult?.get ?? value.get;
    const set = observableResult?.set ?? value.set;
    const init = observableResult?.init;
    const stateName = context.name;

    return {
      get,
      set(nextValue) {
        if (!validate(nextValue)) {
          throw new TypeError(`Invalid assignment to @State accessor "${stateName}"`);
        }
        set.call(
          this,
          freezeSnapshot(
            cloneContractValue(nextValue)
          ) as ContractStatic<Schema>
        );
      },
      init() {
        const initialValue = freezeSnapshot(
          cloneContractValue(definition.default)
        ) as ContractStatic<Schema>;
        return init === undefined ? initialValue : init.call(this, initialValue);
      },
    };
  };
}

export function Store<const Options extends StoreOptions>(
  options: Options
): <Class extends StoreConstructor>(
  value: Class,
  context: ClassDecoratorContext<Class>
) => void {
  return <Class extends StoreConstructor>(
    value: Class,
    context: ClassDecoratorContext<Class>
  ): void => {
    const decoratorMetadata = requireDecoratorMetadata(context.metadata);
    if (hasInheritedStateMetadata(decoratorMetadata)) {
      throw new TypeError('@Store does not support inherited @State accessors');
    }
    if (Object.hasOwn(value, STORE_METADATA)) {
      throw new TypeError(`Duplicate @Store decorator on ${context.name ?? 'anonymous class'}`);
    }

    const states = Object.hasOwn(decoratorMetadata, STATE_DEFINITIONS)
      ? [...(decoratorMetadata[STATE_DEFINITIONS] as readonly MutableStateMetadata[])]
      : [];
    states.sort((left, right) => left.name.localeCompare(right.name));

    const contract = defineModuleContract({
      id: options.id,
      state: Object.fromEntries(
        states.map(state => [state.name, state.definition])
      ),
      nui: {events: {toNui: {}, toClient: {}}, rpc: {toNui: {}, toClient: {}}},
      net: {
        events: {clientToServer: {}, serverToClient: {}},
        rpc: {clientToServer: {}, serverToClient: {}},
      },
      exports: {client: {}, server: {}},
    });
    const metadata: StoreMetadata = Object.freeze({
      id: contract.id,
      states: Object.freeze(
        states.map(state => Object.freeze({...state}))
      ),
    });

    Object.defineProperty(value, STORE_METADATA, {value: metadata});
  };
}

export function getStoreMetadata(store: StoreConstructor): StoreMetadata {
  const metadata = Object.hasOwn(store, STORE_METADATA)
    ? (store as MetadataCarrier)[STORE_METADATA]
    : undefined;
  if (metadata === undefined) {
    throw new TypeError(`Store class ${store.name || '<anonymous>'} is not decorated with @Store`);
  }
  return metadata;
}

export function extractStoreContract(
  store: StoreConstructor,
  boundaries: ModuleBoundaries
): Readonly<ModuleContractInput> {
  const metadata = getStoreMetadata(store);
  return defineModuleContract({
    id: metadata.id,
    state: Object.fromEntries(
      metadata.states.map(state => [state.name, state.definition])
    ),
    nui: boundaries.nui,
    net: boundaries.net,
    exports: boundaries.exports,
  });
}

function validatedStoreRegistrations(registry: StoreRegistry) {
  const registrations: readonly (readonly [string | undefined, StoreConstructor])[] =
    Array.isArray(registry)
      ? (registry as readonly StoreConstructor[]).map(store => [undefined, store] as const)
      : Object.entries(registry as Readonly<Record<string, StoreConstructor>>)
          .sort(([left], [right]) => left.localeCompare(right));
  const ids = new Set<string>();
  return registrations.map(([registeredId, store]) => {
    const metadata = getStoreMetadata(store);
    if (registeredId !== undefined && registeredId !== metadata.id) {
      throw new TypeError(
        `Store registry key "${registeredId}" does not match contract id "${metadata.id}"`
      );
    }
    if (ids.has(metadata.id)) {
      throw new TypeError(`Duplicate store module id: ${metadata.id}`);
    }
    ids.add(metadata.id);
    return {store, metadata};
  });
}

export function extractStoreContracts(
  registry: StoreRegistry,
  boundaryRegistry: Readonly<Record<string, ModuleBoundaries>>
): readonly Readonly<ModuleContractInput>[] {
  const contracts = validatedStoreRegistrations(registry).map(({store, metadata}) => {
    const boundaries = boundaryRegistry[metadata.id];
    if (boundaries === undefined) {
      throw new TypeError(`Missing module boundaries for store: ${metadata.id}`);
    }
    return extractStoreContract(store, boundaries);
  });
  const ids = new Set(contracts.map(contract => contract.id));
  const unknownBoundaryIds = Object.keys(boundaryRegistry)
    .filter(id => !ids.has(id))
    .sort();
  if (unknownBoundaryIds.length > 0) {
    throw new TypeError(`Module boundaries have no registered store: ${unknownBoundaryIds.join(', ')}`);
  }
  contracts.sort((left, right) => left.id.localeCompare(right.id));
  return Object.freeze(contracts);
}

export function defineStoreRegistry<
  const Registry extends StoreRegistry,
>(registry: Registry): Readonly<Registry> {
  validatedStoreRegistrations(registry);
  const copy = Array.isArray(registry)
    ? [...registry]
    : Object.fromEntries(
        Object.entries(registry).sort(([left], [right]) => left.localeCompare(right))
      );
  return Object.freeze(copy) as Readonly<Registry>;
}
