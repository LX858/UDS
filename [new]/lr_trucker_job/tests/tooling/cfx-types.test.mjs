import assert from 'node:assert/strict';
import fs from 'node:fs';
import path from 'node:path';
import test from 'node:test';

import {generateCfxDeclarations} from '../../tooling/cfx/generator.mjs';

const repoRoot = path.resolve(import.meta.dirname, '..', '..');

const gameMetadata = {
  PLAYER: {
    '0x1': {
      name: 'PLAYER_PED_ID',
      params: [],
      results: 'Ped',
    },
    '0x2': {
      name: 'GET_PLAYER_NAME',
      params: [{name: 'player', type: 'Player'}],
      results: 'char*',
    },
    '0x3': {
      name: 'GET_MODEL_DIMENSIONS',
      params: [
        {name: 'modelHash', type: 'Hash'},
        {name: 'minimum', type: 'Vector3*'},
        {name: 'maximum', type: 'Vector3*'},
      ],
      results: 'void',
    },
    '0x4': {
      name: '_0x12345678',
      params: [],
      results: 'void',
    },
  },
};

const cfxMetadata = {
  CFX: {
    '0x10': {
      name: 'CLIENT_ONLY',
      apiset: 'client',
      game: 'gta5',
      params: [{name: 'enabled', type: 'BOOL'}],
      results: 'void',
    },
    '0x11': {
      name: 'SERVER_ONLY',
      apiset: 'server',
      params: [],
      results: 'int',
    },
    '0x12': {
      name: 'SHARED_ONLY',
      apiset: 'shared',
      params: [],
      results: 'BOOL',
    },
    '0x13': {
      name: 'RDR_ONLY',
      apiset: 'client',
      game: 'rdr3',
      params: [],
      results: 'void',
    },
    '0x14': {
      name: 'SEND_NUI_MESSAGE',
      apiset: 'client',
      params: [{name: 'jsonString', type: 'char*'}],
      results: 'BOOL',
    },
    '0x15': {
      name: 'TRIGGER_SERVER_EVENT_INTERNAL',
      apiset: 'client',
      params: [{name: 'eventName', type: 'char*'}],
      results: 'void',
    },
    '0x16': {
      name: 'TRIGGER_CLIENT_EVENT_INTERNAL',
      apiset: 'server',
      params: [{name: 'eventName', type: 'char*'}],
      results: 'void',
    },
    '0x17': {
      name: 'TRIGGER_EVENT_INTERNAL',
      apiset: 'shared',
      params: [{name: 'eventName', type: 'char*'}],
      results: 'void',
    },
    '0x18': {
      name: 'REGISTER_RESOURCE_AS_EVENT_HANDLER',
      apiset: 'shared',
      params: [{name: 'eventName', type: 'char*'}],
      results: 'void',
    },
  },
};

test('generator isolates GTA5 native declarations by runtime side', () => {
  const generated = generateCfxDeclarations({
    gameMetadata,
    cfxMetadata,
    snapshotId: 'fixture',
    handwritten: {client: new Set(), server: new Set(), shared: new Set()},
  });

  assert.match(generated.client, /function PlayerPedId\(\) end/);
  assert.match(generated.client, /function ClientOnly\(enabled\) end/);
  assert.doesNotMatch(
    generated.client,
    /ServerOnly|SharedOnly|RdrOnly|SendNuiMessage|TriggerServerEventInternal/,
  );

  assert.match(generated.server, /function ServerOnly\(\) end/);
  assert.doesNotMatch(
    generated.server,
    /PlayerPedId|ClientOnly|SharedOnly|RdrOnly|TriggerClientEventInternal/,
  );

  assert.match(generated.shared, /function SharedOnly\(\) end/);
  assert.doesNotMatch(
    generated.shared,
    /PlayerPedId|ClientOnly|ServerOnly|RdrOnly|TriggerEventInternal|RegisterResourceAsEventHandler/,
  );
});

test('generator maps hashes, handles and output pointers to LuaLS types', () => {
  const generated = generateCfxDeclarations({
    gameMetadata,
    cfxMetadata: {},
    snapshotId: 'fixture',
    handwritten: {client: new Set(['PlayerPedId']), server: new Set(), shared: new Set()},
  }).client;

  assert.doesNotMatch(generated, /function PlayerPedId/);
  assert.match(generated, /---@param player integer/);
  assert.match(generated, /---@return string/);
  assert.match(generated, /---@param modelHash Hash\|string/);
  assert.match(generated, /---@return vector3 minimum/);
  assert.match(generated, /---@return vector3 maximum/);
  assert.match(generated, /function GetModelDimensions\(modelHash\) end/);
  assert.match(generated, /function N_0x12345678\(\) end/);
});

test('committed CFX snapshot lock records explicit upstream revisions', () => {
  const lock = JSON.parse(
    fs.readFileSync(path.join(repoRoot, 'tooling', 'cfx', 'snapshot.lock.json'), 'utf8'),
  );
  for (const source of Object.values(lock.sources)) {
    assert.match(source.sourceRevision, /^etag:/);
    assert.equal(source.sourceRevision, `etag:${source.etag}`);
    assert.match(source.sha256, /^[a-f0-9]{64}$/);
  }
});
