import Type from 'typebox';
import {
  type ContractStatic,
  defineModuleContract,
  defineStateContract,
  rpc,
} from '@lr/contracts';
import {State, Store} from '@lr/nui-store';
import {
  createNuiRuntime,
  type NuiRuntimeOptions,
} from '../nui/runtime';

const EmptySchema = Type.Object({});
export const FixtureVisibilitySchema = Type.Object({visible: Type.Boolean()});
export const FixturePreferencesSchema = Type.Object({compact: Type.Boolean()});
export const FixtureSettingsSchema = Type.Object({
  locale: Type.Record(Type.String(), Type.String()),
  dev: Type.Boolean(),
});
export const FixtureSnapshotSchema = Type.Object({
  count: Type.Integer(),
  message: Type.String(),
});

export const fixtureContract = defineModuleContract({
  id: 'fixture',
  state: {
    visibility: defineStateContract(FixtureVisibilitySchema, {visible: false}),
    preferences: defineStateContract(FixturePreferencesSchema, {compact: false}),
    settings: defineStateContract(FixtureSettingsSchema, {locale: {}, dev: false}),
    snapshot: defineStateContract(FixtureSnapshotSchema, {count: 0, message: ''}),
  },
  nui: {
    events: {
      toNui: {
        toast: Type.Object({
          level: Type.Union([
            Type.Literal('info'),
            Type.Literal('success'),
            Type.Literal('warning'),
            Type.Literal('error'),
          ]),
          message: Type.String(),
        }),
      },
      toClient: {
        selected: Type.Object({id: Type.String({minLength: 1})}),
      },
    },
    rpc: {
      toNui: {
        confirm: rpc(
          Type.Object({message: Type.String({minLength: 1})}),
          Type.Object({accepted: Type.Boolean()})
        ),
      },
      toClient: {
        close: rpc(EmptySchema, EmptySchema),
        increment: rpc(
          Type.Object({amount: Type.Integer({minimum: 1})}),
          FixtureSnapshotSchema
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

export const fixtureContracts = Object.freeze({fixture: fixtureContract});

export function createFixtureNuiRuntime(
  options: Omit<NuiRuntimeOptions<typeof fixtureContracts>, 'contracts'> = {}
) {
  return createNuiRuntime({...options, contracts: fixtureContracts});
}

@Store({id: 'fixture'})
export class FixtureStore {
  @State(FixtureVisibilitySchema, {visible: false})
  accessor visibility!: ContractStatic<typeof FixtureVisibilitySchema>;

  @State(FixturePreferencesSchema, {compact: false})
  accessor preferences!: ContractStatic<typeof FixturePreferencesSchema>;

  @State(FixtureSettingsSchema, {locale: {}, dev: false})
  accessor settings!: ContractStatic<typeof FixtureSettingsSchema>;

  @State(FixtureSnapshotSchema, {count: 0, message: ''})
  accessor snapshot!: ContractStatic<typeof FixtureSnapshotSchema>;

  get isDev() {
    return this.settings.dev;
  }

  L(key: string, args?: Record<string, string | number>) {
    const template = this.settings.locale[key] ?? key;
    if (!args) return template;
    return Object.entries(args).reduce(
      (value, [argKey, argValue]) =>
        value.replaceAll(`:{${argKey}}`, String(argValue)),
      template
    );
  }
}
