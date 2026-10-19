import type {Static, TSchema} from 'typebox';
import Compile from 'typebox/compile';
import Value from 'typebox/value';

export const CONTRACT_VERSION = 2 as const;
export const NUI_RPC_TIMEOUT_MS = 5_000;
export const NUI_RPC_TIMEOUT_MAX_MS = 60_000;
export const NET_RPC_TIMEOUT_MS = 10_000;
export const NET_RPC_TIMEOUT_MAX_MS = 30_000;
export const NUI_PAYLOAD_MAX_BYTES = 256 * 1024;
export const NET_PAYLOAD_MAX_BYTES = 128 * 1024;

const MODULE_ID_PATTERN = /^[a-z][a-z0-9_]*$/;
const MEMBER_ID_PATTERN = /^[a-z][A-Za-z0-9_]*$/;

const FORBIDDEN_SCHEMA_KEYWORDS = new Set([
  '$anchor',
  '$defs',
  '$dynamicAnchor',
  '$dynamicRef',
  '$recursiveAnchor',
  '$recursiveRef',
  '$ref',
  'allOf',
  'contains',
  'contentEncoding',
  'contentMediaType',
  'dependentRequired',
  'dependentSchemas',
  'else',
  'format',
  'if',
  'not',
  'prefixItems',
  'propertyNames',
  'then',
  'unevaluatedItems',
  'unevaluatedProperties',
]);
const ALLOWED_SCHEMA_KEYWORDS = new Set([
  '$id',
  'additionalProperties',
  'anyOf',
  'const',
  'default',
  'deprecated',
  'description',
  'enum',
  'examples',
  'exclusiveMaximum',
  'exclusiveMinimum',
  'items',
  'maximum',
  'maxItems',
  'maxLength',
  'minimum',
  'minItems',
  'minLength',
  'pattern',
  'patternProperties',
  'properties',
  'readOnly',
  'required',
  'title',
  'type',
  'writeOnly',
]);
const ALLOWED_SCHEMA_TYPES = new Set([
  'array',
  'boolean',
  'integer',
  'null',
  'number',
  'object',
  'string',
]);

export type ContractSchema = TSchema;

export interface StateContract<Schema extends ContractSchema = ContractSchema> {
  readonly schema: Schema;
  readonly default: Static<Schema>;
  readonly patch?: ContractSchema;
}

export interface RpcOptions {
  readonly timeoutMs?: number;
  readonly mutating?: boolean;
  readonly rateLimit?: Readonly<{
    requestsPerSecond: number;
    burst: number;
  }>;
}

export interface RpcContract<
  Request extends ContractSchema = ContractSchema,
  Response extends ContractSchema = ContractSchema,
> {
  readonly request: Request;
  readonly response: Response;
  readonly timeoutMs?: number;
  readonly mutating?: boolean;
  readonly rateLimit?: Readonly<{
    requestsPerSecond: number;
    burst: number;
  }>;
}

type SchemaMap = Readonly<Record<string, ContractSchema>>;
type RpcMap = Readonly<Record<string, RpcContract>>;

export interface ModuleContractInput {
  readonly id: string;
  readonly state: Readonly<Record<string, StateContract>>;
  readonly nui: Readonly<{
    events: Readonly<{toNui: SchemaMap; toClient: SchemaMap}>;
    rpc: Readonly<{toNui: RpcMap; toClient: RpcMap}>;
  }>;
  readonly net: Readonly<{
    events: Readonly<{clientToServer: SchemaMap; serverToClient: SchemaMap}>;
    rpc: Readonly<{clientToServer: RpcMap; serverToClient: RpcMap}>;
  }>;
  readonly exports: Readonly<{client: RpcMap; server: RpcMap}>;
}

export type ModuleBoundaries = Pick<ModuleContractInput, 'nui' | 'net' | 'exports'>;

function cloneJson<T>(value: T): T {
  if (Array.isArray(value)) {
    return value.map(item => cloneJson(item)) as T;
  }
  if (value !== null && typeof value === 'object') {
    const entries = Object.entries(value).map(([key, item]) => [
      key,
      cloneJson(item),
    ]);
    return Object.fromEntries(entries) as T;
  }
  return value;
}

export function cloneContractValue<T>(value: T): T {
  return cloneJson(value);
}

function freezeDeep<T>(value: T): Readonly<T> {
  if (value !== null && typeof value === 'object') {
    for (const item of Object.values(value)) {
      freezeDeep(item);
    }
    Object.freeze(value);
  }
  return value;
}

function normalizeSchema(schema: ContractSchema): ContractSchema {
  const normalized = cloneJson(schema) as Record<string, unknown>;

  const visit = (node: unknown): void => {
    if (Array.isArray(node)) {
      node.forEach(visit);
      return;
    }
    if (node === null || typeof node !== 'object') return;

    const objectNode = node as Record<string, unknown>;
    if (objectNode.type === 'object' && objectNode.additionalProperties === undefined) {
      objectNode.additionalProperties = false;
    }
    Object.values(objectNode).forEach(visit);
  };

  visit(normalized);
  return normalized as ContractSchema;
}

export function assertSupportedSchema(schema: unknown): asserts schema is ContractSchema {
  if (schema === null || typeof schema !== 'object' || Array.isArray(schema)) {
    throw new TypeError('Contract schema must be a JSON Schema object');
  }

  const active = new WeakSet<object>();
  const visit = (node: unknown, path: string): void => {
    if (node === null || typeof node !== 'object' || Array.isArray(node)) {
      throw new TypeError(`Schema at ${path} must be an object`);
    }
    if (active.has(node)) {
      throw new TypeError(`Recursive or cyclic schema at ${path}`);
    }

    active.add(node);
    const schemaNode = node as Record<string, unknown>;
    const declaredTypes = Array.isArray(schemaNode.type)
      ? schemaNode.type
      : schemaNode.type === undefined
        ? []
        : [schemaNode.type];
    for (const declaredType of declaredTypes) {
      if (typeof declaredType !== 'string' || !ALLOWED_SCHEMA_TYPES.has(declaredType)) {
        throw new TypeError(`Unsupported schema type "${String(declaredType)}" at ${path}`);
      }
    }

    const isJsonScalar = (value: unknown) =>
      value === null ||
      typeof value === 'string' ||
      typeof value === 'number' ||
      typeof value === 'boolean';
    if ('const' in schemaNode && !isJsonScalar(schemaNode.const)) {
      throw new TypeError(`const at ${path} must be a JSON scalar`);
    }
    if ('enum' in schemaNode) {
      if (
        !Array.isArray(schemaNode.enum) ||
        schemaNode.enum.length === 0 ||
        !schemaNode.enum.every(isJsonScalar)
      ) {
        throw new TypeError(`enum at ${path} must contain JSON scalar values`);
      }
    }
    if (declaredTypes.includes('array') && !('items' in schemaNode)) {
      throw new TypeError(`Array schema at ${path} must declare items`);
    }

    for (const [key, value] of Object.entries(schemaNode)) {
      if (FORBIDDEN_SCHEMA_KEYWORDS.has(key) || key.startsWith('~')) {
        throw new TypeError(`Unsupported schema keyword "${key}" at ${path}`);
      }
      if (!ALLOWED_SCHEMA_KEYWORDS.has(key)) {
        throw new TypeError(`Unsupported schema keyword "${key}" at ${path}`);
      }
      if (key === 'properties' || key === 'patternProperties') {
        if (value === null || typeof value !== 'object' || Array.isArray(value)) {
          throw new TypeError(`${key} at ${path} must be an object`);
        }
        for (const [name, propertySchema] of Object.entries(value)) {
          visit(propertySchema, `${path}/${key}/${name}`);
        }
      } else if (key === 'items' || (key === 'additionalProperties' && typeof value === 'object')) {
        visit(value, `${path}/${key}`);
      } else if (key === 'anyOf') {
        if (!Array.isArray(value) || value.length === 0) {
          throw new TypeError(`anyOf at ${path} must be a non-empty array`);
        }
        value.forEach((candidate, index) => visit(candidate, `${path}/anyOf/${index}`));
      } else if (
        typeof value === 'function' ||
        typeof value === 'symbol' ||
        typeof value === 'bigint'
      ) {
        throw new TypeError(`Unsupported schema value at ${path}/${key}`);
      }
    }
    active.delete(node);
  };

  visit(schema, '#');
}

export function defineStateContract<const Schema extends ContractSchema>(
  schema: Schema,
  defaultValue: Static<Schema>
): Readonly<StateContract<Schema>> {
  assertSupportedSchema(schema);
  const normalizedSchema = normalizeSchema(schema) as Schema;
  if (!Value.Check(normalizedSchema, defaultValue)) {
    throw new TypeError('Invalid default value for state');
  }

  const schemaRecord = normalizedSchema as unknown as Record<string, unknown>;
  const patch = schemaRecord.type === 'object'
    ? (() => {
        const value = cloneJson(normalizedSchema) as unknown as Record<string, unknown>;
        delete value.required;
        return value as ContractSchema;
      })()
    : undefined;

  return freezeDeep({
    schema: normalizedSchema,
    default: cloneJson(defaultValue),
    ...(patch === undefined ? {} : {patch}),
  }) as Readonly<StateContract<Schema>>;
}

export function rpc<
  const Request extends ContractSchema,
  const Response extends ContractSchema,
>(
  request: Request,
  response: Response,
  options: RpcOptions = {}
): Readonly<RpcContract<Request, Response>> {
  assertSupportedSchema(request);
  assertSupportedSchema(response);

  if (options.timeoutMs !== undefined && (!Number.isInteger(options.timeoutMs) || options.timeoutMs <= 0)) {
    throw new TypeError('RPC timeoutMs must be a positive integer');
  }
  if (options.rateLimit !== undefined) {
    const {requestsPerSecond, burst} = options.rateLimit;
    if (!(requestsPerSecond > 0) || !(burst >= 1)) {
      throw new TypeError('RPC rate limit values must be positive');
    }
  }

  return freezeDeep({
    request: normalizeSchema(request) as Request,
    response: normalizeSchema(response) as Response,
    ...(options.timeoutMs === undefined ? {} : {timeoutMs: options.timeoutMs}),
    ...(options.mutating === undefined ? {} : {mutating: options.mutating}),
    ...(options.rateLimit === undefined
      ? {}
      : {rateLimit: cloneJson(options.rateLimit)}),
  }) as Readonly<RpcContract<Request, Response>>;
}

function validateMemberIdentifier(value: string, label: string, errors: string[]): void {
  if (!MEMBER_ID_PATTERN.test(value)) {
    errors.push(`${label} must match ${MEMBER_ID_PATTERN.source}`);
  }
}

function validateSchemaMap(map: SchemaMap, label: string, errors: string[]): void {
  for (const [name, schema] of Object.entries(map)) {
    validateMemberIdentifier(name, `${label}.${name}`, errors);
    try {
      assertSupportedSchema(schema);
    } catch (error) {
      errors.push(`${label}.${name}: ${error instanceof Error ? error.message : 'invalid schema'}`);
    }
  }
}

function validateRpcMap(
  map: RpcMap,
  label: string,
  timeoutMaxMs: number,
  errors: string[]
): void {
  for (const [name, endpoint] of Object.entries(map)) {
    validateMemberIdentifier(name, `${label}.${name}`, errors);
    for (const [schemaName, schema] of [
      ['request', endpoint.request],
      ['response', endpoint.response],
    ] as const) {
      try {
        assertSupportedSchema(schema);
      } catch (error) {
        errors.push(
          `${label}.${name}.${schemaName}: ${
            error instanceof Error ? error.message : 'invalid schema'
          }`
        );
      }
    }
    if (endpoint.timeoutMs !== undefined && endpoint.timeoutMs > timeoutMaxMs) {
      errors.push(`${label}.${name}.timeoutMs must not exceed ${timeoutMaxMs}`);
    }
  }
}

function pascalIdentifier(value: string): string {
  return value
    .replace(/^[a-z]/, letter => letter.toUpperCase())
    .replace(/_([a-z])/g, (_match, letter: string) => letter.toUpperCase());
}

function validateUniqueNames(
  maps: readonly Readonly<Record<string, unknown>>[],
  label: string,
  errors: string[]
): void {
  const seen = new Set<string>();
  for (const map of maps) {
    for (const name of Object.keys(map)) {
      if (seen.has(name)) errors.push(`Duplicate ${label} endpoint name: ${name}`);
      seen.add(name);
    }
  }
}

function validateGeneratedIdentifiers(
  maps: readonly Readonly<Record<string, unknown>>[],
  label: string,
  errors: string[]
): void {
  const seen = new Map<string, string>();
  for (const map of maps) {
    for (const name of Object.keys(map)) {
      const identifier = pascalIdentifier(name);
      const previous = seen.get(identifier);
      if (previous !== undefined && previous !== name) {
        errors.push(
          `Generated identifier collision in ${label}: ${previous} and ${name} both generate ${identifier}`
        );
      } else {
        seen.set(identifier, name);
      }
    }
  }
}

function validatePublicAccessors(map: RpcMap, label: string, errors: string[]): void {
  const seen = new Map<string, string>();
  for (const name of Object.keys(map)) {
    const accessor = pascalIdentifier(name);
    const previous = seen.get(accessor);
    if (previous) {
      errors.push(
        `Public method accessor collision in ${label}: ${previous} and ${name} both generate ${accessor}`
      );
    } else {
      seen.set(accessor, name);
    }
  }
}

export function validateModuleContract(contract: ModuleContractInput): string[] {
  const errors: string[] = [];
  if (!MODULE_ID_PATTERN.test(contract.id)) {
    errors.push(`Module id must match ${MODULE_ID_PATTERN.source}`);
  }

  for (const [name, definition] of Object.entries(contract.state)) {
    validateMemberIdentifier(name, `state.${name}`, errors);
    try {
      assertSupportedSchema(definition.schema);
      if (!Value.Check(definition.schema, definition.default)) {
        errors.push(`state.${name} has an invalid default value`);
      }
    } catch (error) {
      errors.push(`state.${name}: ${error instanceof Error ? error.message : 'invalid schema'}`);
    }
  }

  validateSchemaMap(contract.nui.events.toNui, 'nui.events.toNui', errors);
  validateSchemaMap(contract.nui.events.toClient, 'nui.events.toClient', errors);
  validateRpcMap(contract.nui.rpc.toNui, 'nui.rpc.toNui', NUI_RPC_TIMEOUT_MAX_MS, errors);
  validateRpcMap(contract.nui.rpc.toClient, 'nui.rpc.toClient', NUI_RPC_TIMEOUT_MAX_MS, errors);
  validateSchemaMap(contract.net.events.clientToServer, 'net.events.clientToServer', errors);
  validateSchemaMap(contract.net.events.serverToClient, 'net.events.serverToClient', errors);
  validateRpcMap(
    contract.net.rpc.clientToServer,
    'net.rpc.clientToServer',
    NET_RPC_TIMEOUT_MAX_MS,
    errors
  );
  validateRpcMap(
    contract.net.rpc.serverToClient,
    'net.rpc.serverToClient',
    NET_RPC_TIMEOUT_MAX_MS,
    errors
  );
  validateRpcMap(contract.exports.client, 'exports.client', NET_RPC_TIMEOUT_MAX_MS, errors);
  validateRpcMap(contract.exports.server, 'exports.server', NET_RPC_TIMEOUT_MAX_MS, errors);
  validateUniqueNames(
    [contract.nui.events.toNui, contract.nui.events.toClient],
    'NUI event',
    errors
  );
  validateUniqueNames(
    [contract.nui.rpc.toNui, contract.nui.rpc.toClient],
    'NUI RPC',
    errors
  );
  validateUniqueNames(
    [
      contract.net.events.clientToServer,
      contract.net.events.serverToClient,
    ],
    'net event',
    errors
  );
  validateUniqueNames(
    [
      contract.net.rpc.clientToServer,
      contract.net.rpc.serverToClient,
    ],
    'net RPC',
    errors
  );
  validateGeneratedIdentifiers([contract.state], 'state', errors);
  validateGeneratedIdentifiers(
    [contract.nui.events.toNui, contract.nui.events.toClient],
    'NUI events',
    errors
  );
  validateGeneratedIdentifiers(
    [contract.nui.rpc.toNui, contract.nui.rpc.toClient],
    'NUI RPC',
    errors
  );
  validateGeneratedIdentifiers(
    [contract.net.events.clientToServer],
    'client-to-server net events',
    errors
  );
  validateGeneratedIdentifiers(
    [contract.net.events.serverToClient],
    'server-to-client net events',
    errors
  );
  validateGeneratedIdentifiers(
    [contract.net.rpc.clientToServer],
    'client-to-server net RPC',
    errors
  );
  validateGeneratedIdentifiers(
    [contract.net.rpc.serverToClient],
    'server-to-client net RPC',
    errors
  );
  validatePublicAccessors(contract.exports.client, 'exports.client', errors);
  validatePublicAccessors(contract.exports.server, 'exports.server', errors);

  return errors;
}

export function defineModuleContract<const Contract extends ModuleContractInput>(
  contract: Contract
): Readonly<Contract> {
  const errors = validateModuleContract(contract);
  if (errors.length > 0) {
    throw new TypeError(`Invalid module contract:\n- ${errors.join('\n- ')}`);
  }

  // The traversal also reaches every nested event/RPC schema and enforces the
  // v2 closed-object default without mutating the caller's contract object.
  return freezeDeep(
    normalizeSchema(contract as unknown as ContractSchema) as unknown as Contract
  ) as Readonly<Contract>;
}

export type ContractStatic<Schema extends ContractSchema> = Static<Schema>;

export type ContractValidator<Value> = (value: unknown) => value is Value;

export function compileValidator<const Schema extends ContractSchema>(
  schema: Schema
): ContractValidator<Static<Schema>> {
  assertSupportedSchema(schema);
  const compiled = Compile(schema);
  return (value: unknown): value is Static<Schema> => compiled.Check(value);
}
