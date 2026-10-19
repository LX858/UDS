import {describe, expect, it} from 'vitest';
import Type, {type Static} from 'typebox';
import type {ContractSchema} from '@lr/contracts';
import {isObservable, isObservableProp} from 'mobx';
import {
  defineStoreRegistry,
  extractStoreContract,
  extractStoreContracts,
  getStoreMetadata,
  State,
  Store,
} from './index';

const CountState = Type.Object({count: Type.Integer({minimum: 0})});
const NameState = Type.String({minLength: 1});

function boundaries() {
  return {
    nui: {events: {toNui: {}, toClient: {}}, rpc: {toNui: {}, toClient: {}}},
    net: {
      events: {clientToServer: {}, serverToClient: {}},
      rpc: {clientToServer: {}, serverToClient: {}},
    },
    exports: {client: {}, server: {}},
  } as const;
}

describe('@lr/nui-store', () => {
  it('validates state schemas and defaults when decorators are declared', () => {
    expect(() => State(CountState, {count: -1})).toThrow(/invalid default value/i);
    expect(() =>
      State({$ref: '#/unsupported'} as unknown as ContractSchema, {})
    ).toThrow(
      /unsupported schema keyword.*\$ref/i
    );
  });

  it('builds deterministic frozen metadata without constructing the store', () => {
    let constructions = 0;

    @Store({id: 'counter'})
    class CounterStore {
      @State(NameState, 'Ready')
      accessor name!: Static<typeof NameState>;

      @State(CountState, {count: 0})
      accessor snapshot!: Static<typeof CountState>;

      constructor() {
        constructions += 1;
        throw new Error('must not construct during extraction');
      }
    }

    const contract = extractStoreContract(CounterStore, boundaries());
    const metadata = getStoreMetadata(CounterStore);

    expect(constructions).toBe(0);
    expect(Object.keys(contract.state)).toEqual(['name', 'snapshot']);
    expect(contract.state.snapshot).not.toHaveProperty('owner');
    expect(metadata.id).toBe('counter');
    expect(metadata.states.map(state => state.name)).toEqual(['name', 'snapshot']);
    expect(Object.isFrozen(metadata)).toBe(true);
    expect(Object.isFrozen(contract)).toBe(true);
  });

  it('clones defaults per instance and composes assignment validation with MobX', () => {
    @Store({id: 'observable_counter'})
    class CounterStore {
      @State(CountState, {count: 0})
      accessor snapshot!: Static<typeof CountState>;
    }

    const first = new CounterStore();
    const second = new CounterStore();

    expect(first.snapshot).not.toBe(second.snapshot);
    expect(isObservableProp(first, 'snapshot')).toBe(true);
    expect(isObservable(first.snapshot)).toBe(false);
    const assigned = {count: 3};
    first.snapshot = assigned;
    assigned.count = 4;
    expect(first.snapshot.count).toBe(3);
    expect(Object.isFrozen(first.snapshot)).toBe(true);
    expect(() => {
      first.snapshot.count = 5;
    }).toThrow();
    expect(second.snapshot.count).toBe(0);
    expect(() => {
      first.snapshot = {count: -1};
    }).toThrow(/invalid assignment.*snapshot/i);
    expect(first.snapshot.count).toBe(3);
  });

  it('extracts explicit registries in module-id order and rejects duplicate ids', () => {
    @Store({id: 'zeta'})
    class ZetaStore {}

    @Store({id: 'alpha'})
    class AlphaStore {}

    @Store({id: 'alpha'})
    class DuplicateAlphaStore {}

    const registry = defineStoreRegistry([ZetaStore, AlphaStore]);
    expect(Object.isFrozen(registry)).toBe(true);
    expect(
      extractStoreContracts(registry, {
        alpha: boundaries(),
        zeta: boundaries(),
      }).map(contract => contract.id)
    ).toEqual(['alpha', 'zeta']);
    expect(() => defineStoreRegistry([AlphaStore, DuplicateAlphaStore])).toThrow(
      /duplicate store module id.*alpha/i
    );
    expect(
      extractStoreContracts(
        {zeta: ZetaStore, alpha: AlphaStore},
        {alpha: boundaries(), zeta: boundaries()}
      ).map(contract => contract.id)
    ).toEqual(['alpha', 'zeta']);
    expect(() =>
      extractStoreContracts({wrong: AlphaStore}, {alpha: boundaries()})
    ).toThrow(/registry key.*wrong.*contract id.*alpha/i);
    expect(() => extractStoreContracts({alpha: AlphaStore}, {})).toThrow(
      /missing module boundaries.*alpha/i
    );
    expect(() =>
      extractStoreContracts(
        {alpha: AlphaStore},
        {alpha: boundaries(), orphan: boundaries()}
      )
    ).toThrow(/boundaries have no registered store.*orphan/i);
  });

  it('rejects static, private, symbol, duplicate, and inherited state accessors', () => {
    expect(() => {
      @Store({id: 'static_state'})
      class StaticStateStore {
        @State(NameState, 'Ready')
        static accessor name: Static<typeof NameState> = 'Ready';
      }
      return StaticStateStore;
    }).toThrow(/static accessor/i);

    expect(() => {
      @Store({id: 'private_state'})
      class PrivateStateStore {
        @State(NameState, 'Ready')
        accessor #name!: Static<typeof NameState>;
      }
      return PrivateStateStore;
    }).toThrow(/private accessor/i);

    expect(() => {
      const stateKey = Symbol('state');
      @Store({id: 'symbol_state'})
      class SymbolStateStore {
        @State(NameState, 'Ready')
        accessor [stateKey]!: Static<typeof NameState>;
      }
      return SymbolStateStore;
    }).toThrow(/symbol-named accessor/i);

    expect(() => {
      @Store({id: 'duplicate_state'})
      class DuplicateStateStore {
        @State(NameState, 'Ready')
        @State(NameState, 'Ready')
        accessor name!: Static<typeof NameState>;
      }
      return DuplicateStateStore;
    }).toThrow(/duplicate @State accessor.*name/i);

    expect(() => {
      class BaseStore {
        @State(NameState, 'Ready')
        accessor name!: Static<typeof NameState>;
      }

      @Store({id: 'derived_state'})
      class DerivedStore extends BaseStore {}
      return DerivedStore;
    }).toThrow(/inherited @State accessors/i);
  });

  it('rejects undecorated classes during extraction', () => {
    class PlainStore {}
    expect(() => extractStoreContract(PlainStore, boundaries())).toThrow(
      /not decorated with @Store/i
    );
  });
});
