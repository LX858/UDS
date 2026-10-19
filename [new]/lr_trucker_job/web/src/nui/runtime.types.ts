import type {ContractSchema, ContractStatic, ModuleContractInput} from '@lr/contracts';
import type {GeneratedContracts} from '../generated/contracts';
import type {NuiKind} from './contracts';

type ContractRegistry = Readonly<Record<string, ModuleContractInput>>;
type SchemaValue<Schema> = Schema extends ContractSchema
  ? ContractStatic<Schema>
  : never;
type RpcRequest<Endpoint> = Endpoint extends {request: infer Request}
  ? Request extends ContractSchema
    ? ContractStatic<Request>
    : never
  : never;
type RpcResponse<Endpoint> = Endpoint extends {response: infer Response}
  ? Response extends ContractSchema
    ? ContractStatic<Response>
    : never
  : never;

export type ModuleName<Contracts extends ContractRegistry = GeneratedContracts> =
  | 'core'
  | Extract<keyof Contracts, string>;

export type NuiEnvelope<
  TModule extends string = ModuleName,
  TKind extends NuiKind = NuiKind,
  TName extends string = string,
  TPayload = unknown,
> = {
  version: 2;
  module: TModule;
  kind: TKind;
  name: TName;
  requestId?: string;
  sessionId?: string;
  revision?: number;
  payload?: TPayload;
  error?: {code: string; message?: string};
};

export interface NuiSubscription {
  dispose(): void;
}

export interface NuiState<T> {
  get(): T;
  set(payload: T): Promise<boolean>;
  subscribe(listener: (payload: T) => void): NuiSubscription;
}

export interface NuiObjectState<T extends object> extends NuiState<T> {
  patch(payload: Partial<T>): Promise<boolean>;
}

export interface NuiEventReceiver<T> {
  subscribe(listener: (payload: T) => void): NuiSubscription;
}

export interface NuiEventSender<T> {
  emit(payload: T): Promise<boolean>;
}

export interface NuiRpcCaller<TRequest, TResponse> {
  call(payload: TRequest): Promise<TResponse>;
}

export interface NuiRpcHandler<TRequest, TResponse> {
  handle(
    handler: (payload: TRequest) => Promise<TResponse> | TResponse
  ): NuiSubscription;
}

type StateEndpoint<State> = State extends {readonly schema: infer Schema}
  ? Schema extends ContractSchema
    ? Schema extends {readonly type: 'object'}
      ? NuiObjectState<ContractStatic<Schema>>
      : NuiState<ContractStatic<Schema>>
    : never
  : never;

export type NuiModuleFacade<Contract extends ModuleContractInput> = {
  state: {
    readonly [Name in keyof Contract['state']]: StateEndpoint<
      Contract['state'][Name]
    >;
  };
  events: {
    readonly [Name in keyof Contract['nui']['events']['toNui']]: NuiEventReceiver<
      SchemaValue<Contract['nui']['events']['toNui'][Name]>
    >;
  } & {
    readonly [Name in keyof Contract['nui']['events']['toClient']]: NuiEventSender<
      SchemaValue<Contract['nui']['events']['toClient'][Name]>
    >;
  };
  rpc: {
    readonly [Name in keyof Contract['nui']['rpc']['toClient']]: NuiRpcCaller<
      RpcRequest<Contract['nui']['rpc']['toClient'][Name]>,
      RpcResponse<Contract['nui']['rpc']['toClient'][Name]>
    >;
  } & {
    readonly [Name in keyof Contract['nui']['rpc']['toNui']]: NuiRpcHandler<
      RpcRequest<Contract['nui']['rpc']['toNui'][Name]>,
      RpcResponse<Contract['nui']['rpc']['toNui'][Name]>
    >;
  };
};

export type GeneratedNuiModules<
  Contracts extends ContractRegistry = GeneratedContracts,
> = {
  readonly [Module in keyof Contracts]: NuiModuleFacade<Contracts[Module]>;
};

type NuiBrowserMockRpc<Contracts extends ContractRegistry> = {
  readonly [Module in keyof Contracts]?: {
    readonly [Name in keyof Contracts[Module]['nui']['rpc']['toClient']]?: (
      payload: RpcRequest<
        Contracts[Module]['nui']['rpc']['toClient'][Name]
      >
    ) =>
      | Promise<
          RpcResponse<Contracts[Module]['nui']['rpc']['toClient'][Name]>
        >
      | RpcResponse<Contracts[Module]['nui']['rpc']['toClient'][Name]>;
  };
};

export interface NuiBrowserMock<
  Contracts extends ContractRegistry = GeneratedContracts,
> {
  rpc?: NuiBrowserMockRpc<Contracts>;
  boot?: (
    dispatch: (envelope: NuiEnvelope<ModuleName<Contracts>>) => boolean
  ) => void | Promise<void>;
  writeState?: (
    request: NuiBrowserMockStateWrite
  ) => NuiBrowserMockStateResult | Promise<NuiBrowserMockStateResult>;
}

export interface NuiBrowserMockStateWrite {
  readonly module: string;
  readonly name: string;
  readonly kind: 'state.set' | 'state.patch';
  readonly requestId: string;
  readonly sessionId: string;
  readonly payload: unknown;
  readonly current: unknown;
  readonly next: unknown;
}

export interface NuiBrowserMockStateResult {
  readonly payload: unknown;
  readonly revision: number;
}

export interface NuiRuntimeOptions<
  Contracts extends ContractRegistry = GeneratedContracts,
> {
  resourceName?: string;
  timeoutMs?: number;
  browserMock?: NuiBrowserMock<NoInfer<Contracts>>;
  onError?: (error: NuiRuntimeError) => void;
  contracts?: Contracts;
}

export interface NuiRuntime<
  Contracts extends ContractRegistry = GeneratedContracts,
> {
  nui: GeneratedNuiModules<Contracts>;
  readonly sessionId: string;
  ready(): Promise<boolean>;
  startBrowserMock(): Promise<void>;
  dispose(): void;
}

export class NuiRuntimeError extends Error {
  constructor(
    public readonly code: string,
    message: string,
    public readonly details?: unknown
  ) {
    super(message);
    this.name = 'NuiRuntimeError';
  }
}
