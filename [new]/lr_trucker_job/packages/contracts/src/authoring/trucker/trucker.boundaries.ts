import Type from 'typebox';
import {rpc, type ModuleBoundaries} from '../../index.ts';
import {
  TruckerActionResultSchema,
  TruckerNoticeSchema,
  TruckerQaScenarioRequestSchema,
  TruckerQaScenarioResponseSchema,
  TruckerServerActionResultSchema,
  TruckerOrderPageSchema,
  TruckerSnapshotSchema,
} from './trucker.schemas.ts';

const EmptySchema = Type.Object({});
const mutationOptions = {
  mutating: true,
  rateLimit: {requestsPerSecond: 4, burst: 8},
} as const;

export const truckerNuiBoundary = {
  events: {toNui: {}, toClient: {}},
  rpc: {
    toNui: {},
    toClient: {
      close: rpc(EmptySchema, TruckerActionResultSchema),
      refresh: rpc(EmptySchema, TruckerActionResultSchema),
      acceptOrder: rpc(
        Type.Object({
          offerId: Type.String({minLength: 1, maxLength: 64}),
          vehicle: Type.Object({
            mode: Type.Literal('rental'),
            key: Type.Union([
              Type.Literal('mule'), Type.Literal('benson'),
              Type.Literal('pounder'), Type.Literal('hauler'),
              Type.Literal('packer'), Type.Literal('phantom'),
            ]),
          }),
        }),
        TruckerActionResultSchema
      ),
      cancelMission: rpc(EmptySchema, TruckerActionResultSchema),
      returnRental: rpc(EmptySchema, TruckerActionResultSchema),
      settleRentalDebt: rpc(EmptySchema, TruckerActionResultSchema),
      upgradeVehicle: rpc(
        Type.Object({vehicleId: Type.Integer({minimum: 1})}),
        TruckerActionResultSchema
      ),
      getBusinessContext: rpc(
        Type.Object({businessId: Type.String({minLength: 1, maxLength: 64})}),
        TruckerActionResultSchema
      ),
      listOrderBoard: rpc(
        Type.Object({
          filter: Type.Literal('all'),
          page: Type.Integer({minimum: 1}),
          pageSize: Type.Integer({minimum: 1, maximum: 20}),
        }),
        TruckerActionResultSchema
      ),
      createBusinessOrder: rpc(
        Type.Object({
          businessId: Type.String({minLength: 1, maxLength: 64}),
          lines: Type.Array(Type.Object({
            itemId: Type.String({minLength: 1, maxLength: 64}),
            quantity: Type.Integer({minimum: 1, maximum: 10000}),
          }), {minItems: 1, maxItems: 6}),
        }),
        TruckerActionResultSchema
      ),
      cancelBusinessOrder: rpc(
        Type.Object({orderId: Type.String({minLength: 1, maxLength: 64})}),
        TruckerActionResultSchema
      ),
    },
  },
} as const satisfies ModuleBoundaries['nui'];

export const truckerNetworkBoundary = {
  events: {
    clientToServer: {},
    serverToClient: {
      sync: Type.Object({snapshot: TruckerSnapshotSchema}),
      notice: TruckerNoticeSchema,
    },
  },
  rpc: {
    clientToServer: {
      getState: rpc(EmptySchema, TruckerSnapshotSchema, {
        rateLimit: {requestsPerSecond: 2, burst: 4},
      }),
      acceptOrder: rpc(
        Type.Object({
          offerId: Type.String({minLength: 1, maxLength: 64}),
          vehicle: Type.Object({
            mode: Type.Literal('rental'),
            key: Type.Union([
              Type.Literal('mule'), Type.Literal('benson'),
              Type.Literal('pounder'), Type.Literal('hauler'),
              Type.Literal('packer'), Type.Literal('phantom'),
            ]),
          }),
        }),
        TruckerServerActionResultSchema,
        mutationOptions
      ),
      cancelMission: rpc(EmptySchema, TruckerServerActionResultSchema, mutationOptions),
      returnRental: rpc(EmptySchema, TruckerServerActionResultSchema, mutationOptions),
      settleRentalDebt: rpc(EmptySchema, TruckerServerActionResultSchema, mutationOptions),
      upgradeVehicle: rpc(
        Type.Object({vehicleId: Type.Integer({minimum: 1})}),
        TruckerServerActionResultSchema,
        {mutating: true, rateLimit: {requestsPerSecond: 1, burst: 2}}
      ),
      advance: rpc(
        Type.Object({expectedStep: Type.Integer({minimum: 1, maximum: 7})}),
        TruckerServerActionResultSchema,
        mutationOptions
      ),
      packageAction: rpc(
        Type.Object({
          action: Type.Union([
            Type.Literal('lift'),
            Type.Literal('load'),
            Type.Literal('deliver'),
          ]),
          packageIndex: Type.Integer({minimum: 1, maximum: 21}),
        }),
        TruckerServerActionResultSchema,
        {mutating: true, rateLimit: {requestsPerSecond: 6, burst: 10}}
      ),
      getBusinessContext: rpc(
        Type.Object({businessId: Type.String({minLength: 1, maxLength: 64})}),
        TruckerServerActionResultSchema,
        {rateLimit: {requestsPerSecond: 2, burst: 4}}
      ),
      listOrderBoard: rpc(
        Type.Object({
          filter: Type.Literal('all'),
          page: Type.Integer({minimum: 1}),
          pageSize: Type.Integer({minimum: 1, maximum: 20}),
        }),
        TruckerOrderPageSchema,
        {rateLimit: {requestsPerSecond: 3, burst: 5}}
      ),
      createBusinessOrder: rpc(
        Type.Object({
          businessId: Type.String({minLength: 1, maxLength: 64}),
          lines: Type.Array(Type.Object({
            itemId: Type.String({minLength: 1, maxLength: 64}),
            quantity: Type.Integer({minimum: 1, maximum: 10000}),
          }), {minItems: 1, maxItems: 6}),
        }),
        TruckerServerActionResultSchema,
        {mutating: true, rateLimit: {requestsPerSecond: 1, burst: 2}}
      ),
      cancelBusinessOrder: rpc(
        Type.Object({orderId: Type.String({minLength: 1, maxLength: 64})}),
        TruckerServerActionResultSchema,
        mutationOptions
      ),
    },
    serverToClient: {},
  },
} as const satisfies ModuleBoundaries['net'];

export const truckerExportBoundary = {
  client: {
    open: rpc(EmptySchema, TruckerActionResultSchema),
    getSnapshot: rpc(EmptySchema, TruckerSnapshotSchema),
  },
  server: {
    qaScenario: rpc(
      TruckerQaScenarioRequestSchema,
      TruckerQaScenarioResponseSchema,
      {mutating: true}
    ),
  },
} as const satisfies ModuleBoundaries['exports'];

export const truckerBoundaries = {
  nui: truckerNuiBoundary,
  net: truckerNetworkBoundary,
  exports: truckerExportBoundary,
} as const satisfies ModuleBoundaries;
