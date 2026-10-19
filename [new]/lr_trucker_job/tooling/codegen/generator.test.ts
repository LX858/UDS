import {describe, expect, it} from 'vitest';
import {
  type ContractSchema,
  defineModuleContract,
  defineStateContract,
  rpc,
} from '../../packages/contracts/src';
import {
  defineStoreRegistry,
  extractStoreContracts,
  State,
  Store,
} from '../../packages/nui-store/src';
import {
  findDuplicateValues,
  findStaleGeneratedModuleArtifacts,
  renderArtifacts,
} from './generator';

const fixtureSnapshotSchema = schema({
  type: 'object',
  required: ['count', 'message'],
  properties: {
    count: {type: 'integer'},
    message: {type: 'string'},
  },
});
const fixtureContract = defineModuleContract({
  id: 'fixture',
  state: {
    snapshot: defineStateContract(fixtureSnapshotSchema, {count: 0, message: ''}),
    preferences: defineStateContract(
      schema({
        type: 'object',
        required: ['compact'],
        properties: {compact: {type: 'boolean'}},
      }),
      {compact: false}
    ),
  },
  nui: {
    events: {
      toNui: {toast: schema({type: 'object'})},
      toClient: {selected: schema({type: 'object'})},
    },
    rpc: {
      toNui: {confirm: rpc(schema({type: 'object'}), schema({type: 'object'}))},
      toClient: {
        close: rpc(schema({type: 'object'}), schema({type: 'object'})),
        increment: rpc(schema({type: 'object'}), fixtureSnapshotSchema),
      },
    },
  },
  net: {
    events: {
      clientToServer: {},
      serverToClient: {notification: schema({type: 'object'})},
    },
    rpc: {
      clientToServer: {
        setMessage: rpc(schema({type: 'object'}), fixtureSnapshotSchema, {
          mutating: true,
        }),
      },
      serverToClient: {},
    },
  },
  exports: {
    client: {
      getSnapshot: rpc(schema({type: 'object'}), fixtureSnapshotSchema),
    },
    server: {
      getSnapshot: rpc(schema({type: 'object'}), fixtureSnapshotSchema),
    },
  },
});
const moduleContracts = Object.freeze([fixtureContract] as const);

describe('contract code generator', () => {
  it('renders byte-identical output for identical contracts', () => {
    const first = renderArtifacts([fixtureContract]);
    const second = renderArtifacts([fixtureContract]);
    expect([...first.entries()]).toEqual([...second.entries()]);
  });

  it('generates every contract supplied by an explicit registry', () => {
    const artifacts = renderArtifacts(moduleContracts);
    const docs = artifacts.get('docs/generated/contracts.md')!;

    for (const contract of moduleContracts) {
      expect(docs).toContain(`## ${contract.id}`);
      expect(artifacts.has(`client/generated/contracts/${contract.id}.lua`)).toBe(true);
      expect(artifacts.has(`server/generated/contracts/${contract.id}.lua`)).toBe(true);
      expect(artifacts.has(`shared/generated/contracts/${contract.id}.lua`)).toBe(true);
    }
  });

  it('finds stale module artifacts on every generated runtime and type side', () => {
    const artifacts = renderArtifacts(moduleContracts);
    const stale = [
      'packages/contracts/src/modules/removed.contract.ts',
      'client/generated/contracts/removed.lua',
      'server/generated/contracts/removed.lua',
      'shared/generated/contracts/removed.lua',
      'types/client/generated/removed.d.lua',
      'types/server/generated/removed.d.lua',
      'types/shared/generated/removed.d.lua',
    ];

    expect(
      findStaleGeneratedModuleArtifacts(
        [...artifacts.keys()].filter(file =>
          file.includes('/generated/') || file.endsWith('.contract.ts')
        ).concat(stale),
        artifacts.keys()
      )
    ).toEqual(stale.sort());
  });

  it('finds duplicate authored store filenames deterministically', () => {
    expect(findDuplicateValues(['zeta', 'fixture', 'zeta', 'alpha', 'fixture'])).toEqual([
      'fixture',
      'zeta',
    ]);
  });

  it('isolates NUI declarations from server and shared artifacts', () => {
    const artifacts = renderArtifacts([fixtureContract]);
    expect(artifacts.get('client/generated/contracts/fixture.lua')).toContain(
      'CompileContract'
    );
    expect(artifacts.get('client/generated/contracts/fixture.lua')).toContain(
      '["version"] = 2'
    );
    expect(artifacts.get('client/generated/contracts/fixture.lua')).not.toContain(
      '["owner"]'
    );
    expect(artifacts.get('server/generated/contracts/fixture.lua')).not.toContain(
      'nui ='
    );
    expect(artifacts.get('shared/generated/contracts/fixture.lua')).not.toContain(
      'nui ='
    );
    expect(artifacts.get('types/server/generated/fixture.d.lua')).not.toContain(
      'Nui'
    );
  });

  it('generates typed web, LuaLS, runtime, and documentation outputs', () => {
    const artifacts = renderArtifacts([fixtureContract]);
    expect(artifacts.has('web/src/generated/contracts.ts')).toBe(true);
    expect(artifacts.has('types/client/generated/fixture.d.lua')).toBe(true);
    expect(artifacts.has('types/server/generated/fixture.d.lua')).toBe(true);
    expect(artifacts.has('types/shared/generated/fixture.d.lua')).toBe(true);
    expect(artifacts.has('docs/generated/contracts.md')).toBe(true);
    expect(artifacts.has('packages/contracts/src/modules/fixture.contract.ts')).toBe(true);
    expect(artifacts.has('packages/contracts/src/modules/index.ts')).toBe(true);
    expect(artifacts.get('web/src/generated/contracts.ts')).toContain(
      "import {defineModuleContract, type ContractStatic} from '@lr/contracts'"
    );
    expect(artifacts.get('web/src/generated/contracts.ts')).not.toContain(
      'storeModules'
    );
    expect(artifacts.get('web/src/generated/contracts.ts')).not.toContain(
      '@lr/contracts/modules'
    );
    expect(artifacts.get('web/src/generated/contracts.ts')).toContain(
      'const fixtureContract = defineModuleContract('
    );
    expect(artifacts.get('web/src/generated/contracts.ts')).not.toContain('setMessage');
    expect(artifacts.get('web/src/generated/contracts.ts')).not.toContain('getSnapshot');
    expect(artifacts.get('web/src/generated/contracts.ts')).not.toContain(
      'requestsPerSecond'
    );
  });

  it('renders decorated store metadata without constructing store instances', () => {
    let constructions = 0;

    @Store({id: 'decorated'})
    class DecoratedStore {
      @State(
        schema({
          type: 'object',
          required: ['count'],
          properties: {count: {type: 'integer'}},
        }),
        {count: 0}
      )
      accessor value!: unknown;

      constructor() {
        constructions += 1;
      }
    }

    const registry = defineStoreRegistry([DecoratedStore]);
    const contracts = extractStoreContracts(registry, {
      decorated: emptyBoundaries(),
    });
    const artifacts = renderArtifacts(contracts);

    expect(constructions).toBe(0);
    expect(artifacts.get('docs/generated/contracts.md')).toContain('## decorated');
    expect(artifacts.get('types/client/generated/decorated.d.lua')).toContain(
      '---@field Set fun(self, value: LRDecoratedStateValue)'
    );
  });

  it('generates side-specific typed net and public accessors without unknown payloads', () => {
    const artifacts = renderArtifacts([fixtureContract]);
    const client = artifacts.get('types/client/generated/fixture.d.lua')!;
    const server = artifacts.get('types/server/generated/fixture.d.lua')!;
    const shared = artifacts.get('types/shared/generated/fixture.d.lua')!;

    expect(client).toContain('---@class LRClientFixtureNet');
    expect(client).toContain('---@field events LRClientFixtureNetEvents');
    expect(client).toContain('---@field rpc LRClientFixtureNetRpc');
    expect(client).toContain('---@class LRClient.Nui');
    expect(client).toContain('---@field Fixture fun(): LRClientFixtureNui');
    expect(client).toContain('---@class LRClientFixtureNuiStateSnapshot');
    expect(client).toContain(
      '---@field Patch fun(self, patch: LRFixtureStateSnapshotPatch)'
    );
    expect(client).toMatch(
      /---@class LRClientFixtureNuiStatePreferences[\s\S]*?---@field Set fun\(self, value: LRFixtureStatePreferences\)/
    );
    expect(client).toContain('---@field setMessage { Call:');
    expect(client).toContain('---@field notification { On:');
    expect(client).toContain('---@class LRClientFixturePublic');
    expect(client).toContain('---@class LRClient.External');
    expect(client).toContain(
      '---@field Fixture fun(resourceName: string): LRClientFixturePublicExternal'
    );
    expect(client).toContain('---@field GetSnapshot fun(self, request:');
    expect(client).not.toContain('unknown');
    expect(client).not.toContain('LRServerFixture');
    expect(client).toContain('LRFixtureExportClientGetSnapshotRequest');
    expect(client).not.toContain('LRFixtureExportServerGetSnapshotRequest');

    expect(server).toContain('---@class LRServerFixtureNet');
    expect(server).toContain('---@field events LRServerFixtureNetEvents');
    expect(server).toContain('---@field rpc LRServerFixtureNetRpc');
    expect(server).toContain('---@field setMessage { Handle:');
    expect(server).toContain('---@field Authorize fun(source: integer');
    expect(server).toContain('---@field notification { Emit:');
    expect(server).toContain('---@class LRServerFixturePublic');
    expect(server).toContain('---@class LRServer.External');
    expect(server).toContain('---@field GetSnapshot fun(self, request:');
    expect(server).not.toContain('unknown');
    expect(server).not.toContain('LRClientFixture');
    expect(server).toContain('LRFixtureExportServerGetSnapshotRequest');
    expect(server).not.toContain('LRFixtureExportClientGetSnapshotRequest');
    expect(shared).not.toContain('LRFixtureExport');
  });

  it('generates separate network namespaces when an event and RPC share a name', () => {
    const emptyObject = schema({type: 'object', properties: {}});
    const contract = defineModuleContract({
      id: 'same_name',
      state: {},
      nui: {events: {toNui: {}, toClient: {}}, rpc: {toNui: {}, toClient: {}}},
      net: {
        events: {clientToServer: {ping: emptyObject}, serverToClient: {}},
        rpc: {
          clientToServer: {ping: rpc(emptyObject, emptyObject)},
          serverToClient: {},
        },
      },
      exports: {client: {}, server: {}},
    });

    const artifacts = renderArtifacts([contract]);
    const client = artifacts.get('types/client/generated/same_name.d.lua')!;
    const server = artifacts.get('types/server/generated/same_name.d.lua')!;

    expect(client).toMatch(
      /---@class LRClientSameNameNetEvents[\s\S]*?---@field ping \{ Emit:/
    );
    expect(client).toMatch(
      /---@class LRClientSameNameNetRpc[\s\S]*?---@field ping \{ Call:/
    );
    expect(server).toMatch(
      /---@class LRServerSameNameNetEvents[\s\S]*?---@field ping \{ Handle:/
    );
    expect(server).toMatch(
      /---@class LRServerSameNameNetRpc[\s\S]*?---@field ping \{ Handle:/
    );
  });

  it('renders advanced subset schema shapes into Lua, LuaLS and docs deterministically', () => {
    const auditContract = defineModuleContract({
      id: 'audit_log',
      state: {
        activeNote: defineStateContract(
          schema({anyOf: [{type: 'string'}, {type: 'null'}]}),
          null
        ),
        entries: defineStateContract(
          schema({
            type: 'array',
            items: {
              type: 'object',
              required: ['id', 'level', 'note'],
              properties: {
                id: {type: 'string'},
                level: {enum: ['info', 'warning', 'error']},
                note: {anyOf: [{type: 'string'}, {type: 'null'}]},
              },
            },
          }),
          []
        ),
        locale: defineStateContract(
          schema({
            type: 'object',
            patternProperties: {'^.*$': {type: 'string'}},
          }),
          {}
        ),
      },
      nui: {
        events: {toNui: {}, toClient: {}},
        rpc: {toNui: {}, toClient: {}},
      },
      net: {
        events: {
          clientToServer: {
            append: schema({
              type: 'object',
              required: ['id', 'count'],
              properties: {id: {type: 'string'}, count: {type: 'integer'}},
            }),
          },
          serverToClient: {
            flushed: schema({
              type: 'object',
              required: ['ok'],
              properties: {ok: {type: 'boolean'}},
            }),
          },
        },
        rpc: {
          clientToServer: {},
          serverToClient: {
            pull: rpc(
              schema({
                type: 'object',
                required: ['limit'],
                properties: {limit: {type: 'integer', minimum: 1}},
              }),
              schema({
                type: 'object',
                required: ['entries'],
                properties: {
                  entries: {
                    type: 'array',
                    items: {
                      type: 'object',
                      required: ['id'],
                      properties: {id: {type: 'string'}},
                    },
                  },
                },
              })
            ),
          },
        },
      },
      exports: {
        client: {},
        server: {
          compact: rpc(
            schema({
              type: 'object',
              required: ['target'],
              properties: {target: {type: 'string'}},
            }),
            schema({
              type: 'object',
              required: ['removed'],
              properties: {removed: {type: 'integer'}},
            }),
            {mutating: true}
          ),
        },
      },
    });

    const artifacts = renderArtifacts([fixtureContract, auditContract]);
    const client = artifacts.get('types/client/generated/audit_log.d.lua')!;
    const server = artifacts.get('types/server/generated/audit_log.d.lua')!;
    const shared = artifacts.get('types/shared/generated/audit_log.d.lua')!;
    const runtime = artifacts.get('client/generated/contracts/audit_log.lua')!;
    const docs = artifacts.get('docs/generated/contracts.md')!;

    expect(client).toContain('LRAuditLogStateEntriesItem');
    expect(client).toContain('"info"|"warning"|"error"');
    expect(client).toContain('note string|nil');
    expect(client).toContain('table<string, string>');
    expect(client).toContain('---@field pull { Handle:');
    expect(server).toContain('---@field pull { Call: fun(self, source: integer');
    expect(server).toContain('---@field compact LRServerAuditLogPublicCompactHandler');
    expect(server).toContain('---@field Authorize fun(invokingResource: string');
    expect(shared).toContain('LRAuditLogNetServerToClientFlushedPayload');
    expect(runtime).toContain('LR.JSON_NULL');
    expect(docs).toContain('## audit_log');
    expect([...artifacts.keys()]).toEqual([...artifacts.keys()].sort());
  });

  it('documents empty contract surfaces as none', () => {
    const emptyContract = defineModuleContract({
      id: 'empty',
      state: {},
      nui: {events: {toNui: {}, toClient: {}}, rpc: {toNui: {}, toClient: {}}},
      net: {
        events: {clientToServer: {}, serverToClient: {}},
        rpc: {clientToServer: {}, serverToClient: {}},
      },
      exports: {client: {}, server: {}},
    });

    const docs = renderArtifacts([emptyContract]).get('docs/generated/contracts.md')!;

    expect(docs).toContain('| State | none |');
    expect(docs).toContain('| NUI events to NUI | none |');
    expect(docs).toContain('| Server exports | none |');
    expect(docs).not.toMatch(/\n\n$/);
  });

  it('rejects deterministic FiveM export name collisions across modules', () => {
    const first = defineModuleContract({
      ...emptyContractInput('foo'),
      exports: {
        client: {bar_baz: rpc(schema({type: 'object'}), schema({type: 'object'}))},
        server: {},
      },
    });
    const second = defineModuleContract({
      ...emptyContractInput('foo_bar'),
      exports: {
        client: {baz: rpc(schema({type: 'object'}), schema({type: 'object'}))},
        server: {},
      },
    });

    expect(() => renderArtifacts([first, second])).toThrow(/export name collision.*foo_bar_baz/i);
  });

  it('preserves distinct identifiers for valid repeated-underscore module IDs', () => {
    const first = defineModuleContract(emptyContractInput('foo_bar'));
    const second = defineModuleContract(emptyContractInput('foo__bar'));
    const artifacts = renderArtifacts([first, second]);
    const index = artifacts.get('packages/contracts/src/modules/index.ts');

    expect(index).toContain('fooBarContract');
    expect(index).toContain('foo_BarContract');
  });
});

function schema(value: ContractSchema): ContractSchema {
  return value;
}

function emptyBoundaries() {
  return {
    nui: {events: {toNui: {}, toClient: {}}, rpc: {toNui: {}, toClient: {}}},
    net: {
      events: {clientToServer: {}, serverToClient: {}},
      rpc: {clientToServer: {}, serverToClient: {}},
    },
    exports: {client: {}, server: {}},
  } as const;
}

function emptyContractInput(id: string) {
  return {
    id,
    state: {},
    ...emptyBoundaries(),
  };
}
