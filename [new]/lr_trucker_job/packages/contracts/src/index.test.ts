import {describe, expect, it} from 'vitest';
import Type from 'typebox';
import {
  assertSupportedSchema,
  CONTRACT_VERSION,
  compileValidator,
  defineModuleContract,
  defineStateContract,
  rpc,
  validateModuleContract,
} from './index';

describe('module contract DSL', () => {
  it('builds a deterministic ownerless v2 contract', () => {
    const contract = defineModuleContract({
      id: 'inventory',
      state: {
        playerSnapshot: defineStateContract(
          Type.Object({id: Type.Integer(), name: Type.String()}),
          {id: 0, name: 'Unknown'}
        ),
        filters: defineStateContract(
          Type.Object({search: Type.String()}),
          {search: ''}
        ),
      },
      nui: {
        events: {toNui: {}, toClient: {}},
        rpc: {
          toNui: {},
          toClient: {
            useItem: rpc(
              Type.Object({itemId: Type.String(), count: Type.Integer({minimum: 1})}),
              Type.Object({ok: Type.Boolean()})
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

    expect(CONTRACT_VERSION).toBe(2);
    expect(contract.id).toBe('inventory');
    expect(contract.state.playerSnapshot).not.toHaveProperty('owner');
    expect(contract.state.filters).not.toHaveProperty('owner');
    expect(
      (contract.nui.rpc.toClient.useItem.request as unknown as Record<string, unknown>)
        .additionalProperties
    ).toBe(false);
    expect(validateModuleContract(contract)).toEqual([]);
  });

  it.each(['Inventory', 'inventory-items', '2inventory', 'inventory.items'])(
    'rejects invalid module id %s',
    id => {
      expect(() =>
        defineModuleContract({
          id,
          state: {},
          nui: {
            events: {toNui: {}, toClient: {}},
            rpc: {toNui: {}, toClient: {}},
          },
          net: {
            events: {clientToServer: {}, serverToClient: {}},
            rpc: {clientToServer: {}, serverToClient: {}},
          },
          exports: {client: {}, server: {}},
        })
      ).toThrow(/module id/i);
    }
  );

  it('rejects schema constructs outside the v2 JSON subset', () => {
    expect(() => assertSupportedSchema({$ref: '#/$defs/Recursive'})).toThrow(
      /unsupported schema keyword.*\$ref/i
    );
  });

  it('rejects custom schema types and keywords', () => {
    expect(() => assertSupportedSchema({type: 'date'})).toThrow(
      /unsupported schema type/i
    );
    expect(() => assertSupportedSchema({type: 'string', transform: 'decode'})).toThrow(
      /unsupported schema keyword/i
    );
  });

  it('rejects malformed, cyclic, and non-json schema nodes', () => {
    expect(() => assertSupportedSchema(null)).toThrow(/json schema object/i);
    expect(() => assertSupportedSchema([])).toThrow(/json schema object/i);
    expect(() => assertSupportedSchema({type: ['string', 'date']})).toThrow(
      /unsupported schema type/i
    );
    expect(() => assertSupportedSchema({type: 'object', properties: []})).toThrow(
      /properties.*object/i
    );
    expect(() => assertSupportedSchema({anyOf: []})).toThrow(/non-empty array/i);
    expect(() =>
      assertSupportedSchema({type: 'object', additionalProperties: {type: 'string'}})
    ).not.toThrow();
    expect(() =>
      assertSupportedSchema({type: 'object', patternProperties: {'^x$': {type: 'string'}}})
    ).not.toThrow();
    expect(() =>
      assertSupportedSchema({
        type: 'object',
        properties: {bad: {type: 'string', description() {}}},
      })
    ).toThrow(/unsupported schema value/i);

    const cyclic: Record<string, unknown> = {type: 'object'};
    cyclic.properties = {self: cyclic};
    expect(() => assertSupportedSchema(cyclic)).toThrow(/recursive or cyclic/i);
  });

  it('rejects schema literals and arrays that Lua codegen cannot represent', () => {
    expect(() =>
      assertSupportedSchema({enum: [{kind: 'object-literal'}]} as never)
    ).toThrow(/enum.*JSON scalar/i);
    expect(() =>
      assertSupportedSchema({const: ['array-literal']} as never)
    ).toThrow(/const.*JSON scalar/i);
    expect(() => assertSupportedSchema({type: 'array'} as never)).toThrow(/items/i);
  });

  it('rejects a default value that does not match its state schema', () => {
    expect(() =>
      defineStateContract(
        Type.Object({count: Type.Integer()}),
        // @ts-expect-error Runtime validation must also reject untyped consumers.
        {count: 'one'}
      )
    ).toThrow(/default value/i);
  });

  it('compiles reusable validators and object patch schemas', () => {
    const definition = defineStateContract(
      Type.Object({compact: Type.Boolean(), label: Type.String()}),
      {compact: false, label: ''}
    );
    expect(definition.patch).toBeDefined();
    const validatePatch = compileValidator(definition.patch!);
    expect(validatePatch({compact: true})).toBe(true);
    expect(validatePatch({compact: 'yes'})).toBe(false);
    expect(validatePatch({injected: true})).toBe(false);
  });

  it('supports nullable unions, literal enums, arrays and records in the v2 subset', () => {
    const schema = Type.Object({
      id: Type.String({minLength: 1}),
      tags: Type.Array(Type.String()),
      mode: Type.Union([Type.Literal('compact'), Type.Literal('full')]),
      note: Type.Union([Type.String(), Type.Null()]),
      locale: Type.Record(Type.String(), Type.String()),
    });
    const validate = compileValidator(schema);

    expect(
      validate({
        id: 'player-1',
        tags: ['vip'],
        mode: 'compact',
        note: null,
        locale: {close: 'Close'},
      })
    ).toBe(true);
    expect(
      validate({
        id: 'player-1',
        tags: ['vip'],
        mode: 'invalid',
        note: null,
        locale: {close: 'Close'},
      })
    ).toBe(false);
  });

  it('reports validation errors across every contract surface', () => {
    const badRpc = {
      request: Type.Object({id: Type.String()}),
      response: Type.Object({ok: Type.Boolean()}),
      timeoutMs: 99_999,
      rateLimit: {requestsPerSecond: 1, burst: 1},
    };
    const errors = validateModuleContract({
      id: 'Bad-Module',
      state: {
        'bad-state': {
          schema: Type.Object({count: Type.Integer()}),
          default: {count: 'one'},
        } as never,
      },
      nui: {
        events: {
          toNui: {'bad-event': Type.Object({})},
          toClient: {badEvent: {$ref: '#/bad'} as never},
        },
        rpc: {toNui: {tooSlow: badRpc}, toClient: {alsoSlow: badRpc}},
      },
      net: {
        events: {
          clientToServer: {'bad-event': Type.Object({})},
          serverToClient: {badEvent: {$ref: '#/bad'} as never},
        },
        rpc: {
          clientToServer: {tooSlow: badRpc},
          serverToClient: {alsoSlow: badRpc},
        },
      },
      exports: {client: {tooSlow: badRpc}, server: {alsoSlow: badRpc}},
    });

    expect(errors).toEqual(
      expect.arrayContaining([
        expect.stringMatching(/Module id/),
        expect.stringMatching(/state\.bad-state/),
        expect.stringMatching(/invalid default value/),
        expect.stringMatching(/nui\.events\.toClient\.badEvent/),
        expect.stringMatching(/nui\.rpc\.toNui\.tooSlow\.timeoutMs/),
        expect.stringMatching(/net\.rpc\.clientToServer\.tooSlow\.timeoutMs/),
        expect.stringMatching(/exports\.server\.alsoSlow\.timeoutMs/),
      ])
    );
  });

  it('validates endpoint namespaces and generated public method collisions before boot', () => {
    const sharedEventAndRpcName = defineInput({
      net: {
        events: {
          clientToServer: {ping: Type.Object({})},
          serverToClient: {},
        },
        rpc: {
          clientToServer: {
            ping: rpc(Type.Object({}), Type.Object({})),
          },
          serverToClient: {},
        },
      },
    });
    expect(() => defineModuleContract(sharedEventAndRpcName)).not.toThrow();

    const duplicateNetEventName = defineInput({
      net: {
        events: {
          clientToServer: {ping: Type.Object({})},
          serverToClient: {ping: Type.Object({})},
        },
        rpc: {clientToServer: {}, serverToClient: {}},
      },
    });
    expect(() => defineModuleContract(duplicateNetEventName)).toThrow(
      /duplicate net event endpoint.*ping/i
    );

    const duplicateNetRpcName = defineInput({
      net: {
        events: {clientToServer: {}, serverToClient: {}},
        rpc: {
          clientToServer: {ping: rpc(Type.Object({}), Type.Object({}))},
          serverToClient: {ping: rpc(Type.Object({}), Type.Object({}))},
        },
      },
    });
    expect(() => defineModuleContract(duplicateNetRpcName)).toThrow(
      /duplicate net RPC endpoint.*ping/i
    );

    const duplicatePublicMethod = defineInput({
      exports: {
        client: {
          get_snapshot: rpc(Type.Object({}), Type.Object({})),
          getSnapshot: rpc(Type.Object({}), Type.Object({})),
        },
        server: {},
      },
    });
    expect(() => defineModuleContract(duplicatePublicMethod)).toThrow(
      /public method accessor collision/i
    );

    const duplicateStateIdentifier = defineInput({
      state: {
        fooBar: defineStateContract(Type.Object({value: Type.String()}), {value: 'a'}),
        foo_bar: defineStateContract(Type.Object({value: Type.Integer()}), {value: 1}),
      },
    });
    expect(() => defineModuleContract(duplicateStateIdentifier)).toThrow(
      /generated identifier collision in state.*fooBar.*foo_bar.*FooBar/i
    );

    const duplicateNuiIdentifier = defineInput({
      nui: {
        events: {
          toNui: {itemChanged: Type.Object({})},
          toClient: {item_changed: Type.Object({})},
        },
        rpc: {toNui: {}, toClient: {}},
      },
    });
    expect(() => defineModuleContract(duplicateNuiIdentifier)).toThrow(
      /generated identifier collision in NUI events.*itemChanged.*item_changed.*ItemChanged/i
    );
  });

  it('rejects invalid RPC options before code generation', () => {
    expect(() =>
      rpc(Type.Object({}), Type.Object({}), {timeoutMs: 0})
    ).toThrow(/timeoutMs/);
    expect(() =>
      rpc(Type.Object({}), Type.Object({}), {
        rateLimit: {requestsPerSecond: 0, burst: 1},
      })
    ).toThrow(/rate limit/);
    expect(() =>
      rpc(Type.Object({}), Type.Object({}), {
        rateLimit: {requestsPerSecond: 1, burst: 0},
      })
    ).toThrow(/rate limit/);
  });

  it('freezes contracts and keeps caller input immutable while normalizing objects', () => {
    const sourceSchema = Type.Object({name: Type.String()});
    const contract = defineModuleContract({
      id: 'frozen',
      state: {
        profile: defineStateContract(sourceSchema, {name: 'Ada'}),
      },
      nui: {events: {toNui: {}, toClient: {}}, rpc: {toNui: {}, toClient: {}}},
      net: {
        events: {clientToServer: {}, serverToClient: {}},
        rpc: {clientToServer: {}, serverToClient: {}},
      },
      exports: {client: {}, server: {}},
    });

    expect(
      (sourceSchema as unknown as Record<string, unknown>).additionalProperties
    ).toBeUndefined();
    expect(
      (contract.state.profile.schema as unknown as Record<string, unknown>)
        .additionalProperties
    ).toBe(false);
    expect(Object.isFrozen(contract)).toBe(true);
    expect(() => {
      (contract.state.profile.default as {name: string}).name = 'Grace';
    }).toThrow();
    expect(contract.state.profile.default.name).toBe('Ada');
  });
});

function defineInput(
  overrides: Partial<Parameters<typeof defineModuleContract>[0]>
): Parameters<typeof defineModuleContract>[0] {
  return {
    id: 'collision',
    state: {},
    nui: {events: {toNui: {}, toClient: {}}, rpc: {toNui: {}, toClient: {}}},
    net: {
      events: {clientToServer: {}, serverToClient: {}},
      rpc: {clientToServer: {}, serverToClient: {}},
    },
    exports: {client: {}, server: {}},
    ...overrides,
  };
}
