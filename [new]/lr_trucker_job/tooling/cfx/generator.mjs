const LUA_RESERVED_WORDS = new Set([
  'and',
  'break',
  'do',
  'else',
  'elseif',
  'end',
  'false',
  'for',
  'function',
  'goto',
  'if',
  'in',
  'local',
  'nil',
  'not',
  'or',
  'repeat',
  'return',
  'then',
  'true',
  'until',
  'while',
]);

// These low-level aliases bypass the bounded/validated v2 transports. Core uses
// the explicit handwritten FiveM APIs it owns; feature code must never receive
// autocomplete for alternate internal entry points from upstream metadata.
export const SUPPRESSED_NATIVE_NAMES = new Set([
  'RegisterRawNuiCallback',
  'RegisterResourceAsEventHandler',
  'SendNuiMessage',
  'TriggerClientEventInternal',
  'TriggerEventInternal',
  'TriggerLatentClientEventInternal',
  'TriggerLatentServerEventInternal',
  'TriggerServerEventInternal',
  'UnregisterRawNuiCallback',
]);

function luaFunctionName(name) {
  if (typeof name !== 'string' || name.length === 0) return undefined;
  const normalized = name
    .toLowerCase()
    .replace(/0x/g, 'n_0x')
    .replace(/_([a-z])/g, (_, letter) => letter.toUpperCase())
    .replace(/^([a-z])/, (_, letter) => letter.toUpperCase());
  return /^[A-Za-z_][A-Za-z0-9_]*$/.test(normalized) ? normalized : undefined;
}

function luaParameterName(name, index, usedNames) {
  let normalized = typeof name === 'string' ? name.replace(/[^A-Za-z0-9_]/g, '_') : '';
  if (!/^[A-Za-z_]/.test(normalized)) normalized = `param${index + 1}`;
  if (LUA_RESERVED_WORDS.has(normalized)) normalized = `${normalized}_`;
  if (normalized.length === 0) normalized = `param${index + 1}`;

  const base = normalized;
  let suffix = 2;
  while (usedNames.has(normalized)) {
    normalized = `${base}${suffix}`;
    suffix += 1;
  }
  usedNames.add(normalized);
  return normalized;
}

function luaType(nativeType, {parameter = false} = {}) {
  const type = typeof nativeType === 'string' ? nativeType.trim() : 'Any';
  const base = type.endsWith('*') && type !== 'char*' ? type.slice(0, -1) : type;

  if (base === 'Object') return 'integer';
  if (base === 'object') return 'table';

  switch (base.toLowerCase()) {
    case 'void':
      return undefined;
    case 'bool':
      return 'boolean';
    case 'float':
    case 'double':
      return 'number';
    case 'int':
    case 'long':
    case 'player':
    case 'vehicle':
    case 'blip':
    case 'cam':
    case 'fireid':
    case 'pickup':
    case 'scrhandle':
      return 'integer';
    case 'entity':
      return 'Entity';
    case 'ped':
      return 'Ped';
    case 'hash':
      return parameter ? 'Hash|string' : 'Hash';
    case 'vector3':
      return 'vector3';
    case 'char*':
      return 'string';
    case 'func':
      return 'function';
    case 'any':
    default:
      return 'unknown';
  }
}

function isOutputPointer(type) {
  return typeof type === 'string' && type.endsWith('*') && type !== 'char*';
}

function flattenMetadata(metadata) {
  if (!metadata || typeof metadata !== 'object') return [];
  const result = [];
  for (const namespace of Object.values(metadata)) {
    if (!namespace || typeof namespace !== 'object') continue;
    for (const native of Object.values(namespace)) {
      if (native && typeof native === 'object') result.push(native);
    }
  }
  return result;
}

function expandAliases(native) {
  const names = [native.name, ...(Array.isArray(native.aliases) ? native.aliases : [])];
  return names.map(name => ({...native, name}));
}

function renderNative(native) {
  const name = luaFunctionName(native.name);
  if (!name) return undefined;

  const usedNames = new Set();
  const parameters = [];
  const returns = [];
  for (const [index, parameter] of (native.params ?? []).entries()) {
    const parameterName = luaParameterName(parameter?.name, index, usedNames);
    if (isOutputPointer(parameter?.type)) {
      returns.push({name: parameterName, type: luaType(parameter.type)});
    } else {
      parameters.push({name: parameterName, type: luaType(parameter?.type, {parameter: true})});
    }
  }

  const resultType = luaType(native.results);
  if (resultType) returns.unshift({type: resultType});

  const lines = [];
  for (const parameter of parameters) lines.push(`---@param ${parameter.name} ${parameter.type}`);
  for (const result of returns) {
    lines.push(`---@return ${result.type}${result.name ? ` ${result.name}` : ''}`);
  }
  lines.push(`function ${name}(${parameters.map(parameter => parameter.name).join(', ')}) end`);
  return {name, text: lines.join('\n')};
}

function renderSide(side, natives, snapshotId, handwritten) {
  const rendered = new Map();
  for (const native of natives.flatMap(expandAliases)) {
    const definition = renderNative(native);
    if (
      !definition ||
      SUPPRESSED_NATIVE_NAMES.has(definition.name) ||
      handwritten.has(definition.name) ||
      rendered.has(definition.name)
    ) {
      continue;
    }
    rendered.set(definition.name, definition.text);
  }

  const body = [...rendered.entries()]
    .sort(([left], [right]) => left.localeCompare(right, 'en'))
    .map(([, declaration]) => declaration)
    .join('\n\n');
  return `---@meta\n\n-- Generated from pinned CitizenFX metadata snapshot ${snapshotId}. Do not edit.\n${
    body ? `\n${body}\n` : ''
  }`;
}

/**
 * Generates side-isolated LuaLS declarations from the official GTA5/CitizenFX
 * metadata shape. Base GTA natives are client-only; CFX natives follow apiset.
 */
export function generateCfxDeclarations({
  gameMetadata,
  cfxMetadata,
  snapshotId,
  handwritten = {client: new Set(), server: new Set(), shared: new Set()},
}) {
  const sides = {client: [], server: [], shared: []};
  for (const native of flattenMetadata(gameMetadata)) {
    const side = native.apiset === 'server' ? 'server' : 'client';
    sides[side].push(native);
  }
  for (const native of flattenMetadata(cfxMetadata)) {
    if (native.game && native.game !== 'gta5') continue;
    if (native.apiset === 'client' || native.apiset === 'server' || native.apiset === 'shared') {
      sides[native.apiset].push(native);
    }
  }

  return {
    client: renderSide('client', sides.client, snapshotId, handwritten.client ?? new Set()),
    server: renderSide('server', sides.server, snapshotId, handwritten.server ?? new Set()),
    shared: renderSide('shared', sides.shared, snapshotId, handwritten.shared ?? new Set()),
  };
}

export function declaredFunctions(source) {
  return new Set(
    [...source.matchAll(/^function\s+([A-Za-z_][A-Za-z0-9_]*)\s*\(/gm)].map(match => match[1]),
  );
}
