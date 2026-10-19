import type {ContractSchema} from '@lr/contracts';
import {
  CONTRACT_VERSION,
  NUI_PAYLOAD_MAX_BYTES,
  NUI_RPC_TIMEOUT_MS,
  NUI_RPC_TIMEOUT_MAX_MS,
  compileValidator,
} from '@lr/contracts';
import {generatedContracts} from '../generated/contracts';

export const NUI_VERSION = CONTRACT_VERSION;
export const LR_BRIDGE_ENDPOINT = 'lr_bridge';
export {generatedContracts};
export {compileValidator};
export {NUI_PAYLOAD_MAX_BYTES, NUI_RPC_TIMEOUT_MAX_MS, NUI_RPC_TIMEOUT_MS};
export type {ContractSchema};

export type NuiKind =
  | 'state.snapshot'
  | 'state.set'
  | 'state.patch'
  | 'event'
  | 'rpc.request'
  | 'rpc.response'
  | 'rpc.error';
