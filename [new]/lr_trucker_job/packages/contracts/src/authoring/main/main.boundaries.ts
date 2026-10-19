import type {ModuleBoundaries} from '../../index.ts';

export const mainNuiBoundary = {
  events: {toNui: {}, toClient: {}},
  rpc: {toNui: {}, toClient: {}},
} as const satisfies ModuleBoundaries['nui'];

export const mainNetworkBoundary = {
  events: {clientToServer: {}, serverToClient: {}},
  rpc: {clientToServer: {}, serverToClient: {}},
} as const satisfies ModuleBoundaries['net'];

export const mainExportBoundary = {
  client: {},
  server: {},
} as const satisfies ModuleBoundaries['exports'];

export const mainBoundaries = {
  nui: mainNuiBoundary,
  net: mainNetworkBoundary,
  exports: mainExportBoundary,
} as const satisfies ModuleBoundaries;
