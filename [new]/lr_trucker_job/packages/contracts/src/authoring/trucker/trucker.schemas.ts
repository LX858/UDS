import Type from 'typebox';

export const TruckerNoticeTypeSchema = Type.Union([
  Type.Literal('inform'),
  Type.Literal('success'),
  Type.Literal('warning'),
  Type.Literal('error'),
]);

export const TruckerVisibilitySchema = Type.Object({
  visible: Type.Boolean(),
});

export const TruckerSettingsSchema = Type.Object({
  locale: Type.Record(Type.String(), Type.String()),
  dev: Type.Boolean(),
});

export const TruckerOrderLineSchema = Type.Object({
  destinationItemId: Type.String({maxLength: 64}),
  destinationLabel: Type.String({minLength: 1, maxLength: 96}),
  itemId: Type.String({minLength: 1, maxLength: 64}),
  label: Type.String({minLength: 1, maxLength: 96}),
  category: Type.String({maxLength: 32}),
  quantity: Type.Integer({minimum: 1, maximum: 10000}),
  unitPrice: Type.Integer({minimum: 0}),
  subtotal: Type.Integer({minimum: 0}),
  packages: Type.Integer({minimum: 1, maximum: 21}),
  destinationAmount: Type.Integer({minimum: 1, maximum: 1000000}),
  destinationUnit: Type.Union([Type.Literal('item'), Type.Literal('liter')]),
});

export const TruckerOrderSchema = Type.Object({
  id: Type.String({minLength: 1, maxLength: 64}),
  routeIndex: Type.Integer({minimum: 1, maximum: 64}),
  name: Type.String({minLength: 1, maxLength: 128}),
  level: Type.Integer({minimum: 1}),
  itemId: Type.String({minLength: 1, maxLength: 64}),
  itemLabel: Type.String({minLength: 1, maxLength: 96}),
  destination: Type.String({minLength: 1, maxLength: 128}),
  packageAmount: Type.Integer({minimum: 1, maximum: 21}),
  packagePrice: Type.Integer({minimum: 0}),
  logisticsUnits: Type.Integer({minimum: 1, maximum: 1000}),
  marketStatus: Type.Union([
    Type.Literal('shortage'),
    Type.Literal('balanced'),
    Type.Literal('surplus'),
  ]),
  marketBonus: Type.Integer({minimum: 0, maximum: 75}),
  availability: Type.Union([
    Type.Literal('available'),
    Type.Literal('route_busy'),
    Type.Literal('stock_low'),
    Type.Literal('source_unavailable'),
  ]),
  reward: Type.Integer({minimum: 0}),
  effectiveReward: Type.Integer({minimum: 0}),
  xp: Type.Integer({minimum: 0}),
  cargoCategory: Type.String({maxLength: 32}),
  categoryKeys: Type.Array(Type.String({maxLength: 32}), {maxItems: 5}),
  requiredVehicleTier: Type.Integer({minimum: 0, maximum: 3}),
  canAccept: Type.Boolean(),
  lockReason: Type.String({maxLength: 128}),
  kind: Type.Literal('business'),
  cargoMode: Type.Union([Type.Literal('pallets'), Type.Literal('tanker')]),
  businessId: Type.String({maxLength: 64}),
  businessLabel: Type.String({maxLength: 96}),
  businessStatus: Type.Union([
    Type.Literal(''), Type.Literal('waiting_stock'), Type.Literal('available'),
    Type.Literal('reserving'), Type.Literal('in_transit'),
    Type.Literal('delivered'), Type.Literal('cancelled'),
  ]),
  distanceKm: Type.Number({minimum: 0, maximum: 1000}),
  lines: Type.Array(TruckerOrderLineSchema, {maxItems: 6}),
});

export const TruckerOfferSchema = Type.Object({
  id: Type.String({minLength: 1, maxLength: 64}),
  level: Type.Integer({minimum: 1}),
  categories: Type.Array(Type.String({minLength: 1, maxLength: 32}), {minItems: 1, maxItems: 5}),
  reward: Type.Integer({minimum: 0}),
  rentalRewards: Type.Array(Type.Object({
    key: Type.Union([
      Type.Literal('mule'), Type.Literal('benson'), Type.Literal('pounder'),
      Type.Literal('hauler'), Type.Literal('packer'), Type.Literal('phantom'),
    ]),
    reward: Type.Integer({minimum: 0}),
  }), {maxItems: 6}),
  availability: Type.Union([
    Type.Literal('available'), Type.Literal('route_busy'),
    Type.Literal('stock_low'), Type.Literal('source_unavailable'),
  ]),
  canAccept: Type.Boolean(),
  lockReason: Type.String({maxLength: 128}),
});

export const TruckerOrderPageSchema = Type.Object({
  filter: Type.Literal('all'),
  page: Type.Integer({minimum: 1}),
  pageSize: Type.Integer({minimum: 1, maximum: 20}),
  total: Type.Integer({minimum: 0}),
  items: Type.Array(TruckerOfferSchema, {maxItems: 20}),
});

export const TruckerBusinessCatalogItemSchema = Type.Object({
  destinationItemId: Type.String({maxLength: 64}),
  destinationLabel: Type.String({minLength: 1, maxLength: 96}),
  itemId: Type.String({minLength: 1, maxLength: 64}),
  label: Type.String({minLength: 1, maxLength: 96}),
  category: Type.String({maxLength: 32}),
  unitPrice: Type.Integer({minimum: 0}),
  available: Type.Integer({minimum: 0}),
  unitsPerPackage: Type.Integer({minimum: 1, maximum: 1000}),
  destinationMultiplier: Type.Integer({minimum: 1, maximum: 10000}),
  destinationUnit: Type.Union([Type.Literal('item'), Type.Literal('liter')]),
});

export const TruckerBusinessContextSchema = Type.Object({
  active: Type.Boolean(),
  sourceOnline: Type.Boolean(),
  businessId: Type.String({maxLength: 64}),
  label: Type.String({maxLength: 96}),
  balance: Type.Integer({minimum: 0}),
  distanceKm: Type.Number({minimum: 0, maximum: 1000}),
  feeBase: Type.Integer({minimum: 0}),
  feePerKm: Type.Integer({minimum: 0}),
  feePerPackage: Type.Integer({minimum: 0}),
  feeMaximum: Type.Integer({minimum: 0}),
  feeRate: Type.Integer({minimum: 0, maximum: 100}),
  catalog: Type.Array(TruckerBusinessCatalogItemSchema, {maxItems: 16}),
  orders: Type.Array(TruckerOrderSchema, {maxItems: 20}),
});

export const TruckerPackageSchema = Type.Object({
  index: Type.Integer({minimum: 1, maximum: 21}),
  netId: Type.Integer({minimum: 0}),
  state: Type.Union([
    Type.Literal('waiting'),
    Type.Literal('carried'),
    Type.Literal('loaded'),
    Type.Literal('unloading'),
    Type.Literal('delivered'),
  ]),
  carrierSource: Type.Integer({minimum: 0}),
  slot: Type.Integer({minimum: 0, maximum: 21}),
});

const TruckerCoordinateSchema = Type.Object({
  x: Type.Number(),
  y: Type.Number(),
  z: Type.Number(),
  w: Type.Number(),
});

export const TruckerMissionSchema = Type.Object({
  active: Type.Boolean(),
  status: Type.Union([
    Type.Literal('idle'),
    Type.Literal('active'),
    Type.Literal('completed'),
  ]),
  id: Type.String({maxLength: 64}),
  routeIndex: Type.Integer({minimum: 0, maximum: 64}),
  deliveryRouteIndex: Type.Integer({minimum: 0, maximum: 64}),
  name: Type.String({maxLength: 128}),
  itemLabel: Type.String({maxLength: 96}),
  destination: Type.String({maxLength: 128}),
  logisticsUnits: Type.Integer({minimum: 0, maximum: 1000}),
  vehicleMode: Type.Union([Type.Literal(''), Type.Literal('owned'), Type.Literal('rental')]),
  vehicleModel: Type.String({maxLength: 32}),
  ownedVehicleId: Type.Integer({minimum: 0}),
  vehiclePlate: Type.String({maxLength: 15}),
  step: Type.Integer({minimum: 0, maximum: 7}),
  packageAmount: Type.Integer({minimum: 0, maximum: 21}),
  loaded: Type.Integer({minimum: 0, maximum: 21}),
  delivered: Type.Integer({minimum: 0, maximum: 21}),
  reward: Type.Integer({minimum: 0}),
  xp: Type.Integer({minimum: 0}),
  truckNetId: Type.Integer({minimum: 0}),
  trailerNetId: Type.Integer({minimum: 0}),
  escortNetId: Type.Integer({minimum: 0}),
  packages: Type.Array(TruckerPackageSchema, {maxItems: 21}),
  orderKind: Type.Union([Type.Literal('market'), Type.Literal('business')]),
  cargoMode: Type.Union([Type.Literal('pallets'), Type.Literal('tanker')]),
  businessId: Type.String({maxLength: 64}),
  lines: Type.Array(TruckerOrderLineSchema, {maxItems: 6}),
  fuelLiters: Type.Integer({minimum: 0, maximum: 1000000}),
  fuelProgress: Type.Integer({minimum: 0, maximum: 100}),
  pickupCoords: TruckerCoordinateSchema,
  deliveryCoords: TruckerCoordinateSchema,
});

export const TruckerSnapshotSchema = Type.Object({
  player: Type.Object({
    source: Type.Integer({minimum: 0}),
    citizenId: Type.String({maxLength: 64}),
    name: Type.String({maxLength: 96}),
    cash: Type.Integer({minimum: 0}),
    bank: Type.Integer({minimum: 0}),
    level: Type.Integer({minimum: 1}),
    xp: Type.Integer({minimum: 0}),
  }),
  orderPage: TruckerOrderPageSchema,
  business: TruckerBusinessContextSchema,
  fleet: Type.Object({
    bank: Type.Integer({minimum: 0}),
    ownedVehicles: Type.Array(Type.Object({
      vehicleId: Type.Integer({minimum: 1}),
      model: Type.String({minLength: 1, maxLength: 32}),
      plate: Type.String({minLength: 1, maxLength: 15}),
      garage: Type.String({maxLength: 64}),
      state: Type.Union([
        Type.Literal('out'),
        Type.Literal('garaged'),
        Type.Literal('impounded'),
      ]),
      tier: Type.Integer({minimum: 1, maximum: 3}),
      capacity: Type.Integer({minimum: 1, maximum: 250}),
      nextUpgradePrice: Type.Integer({minimum: 0}),
      available: Type.Boolean(),
      unavailableReason: Type.String({maxLength: 128}),
    }), {maxItems: 32}),
    rentalOptions: Type.Array(Type.Object({
      key: Type.Union([
        Type.Literal('mule'),
        Type.Literal('benson'),
        Type.Literal('pounder'),
        Type.Literal('hauler'),
        Type.Literal('packer'),
        Type.Literal('phantom'),
      ]),
      label: Type.String({maxLength: 64}),
      model: Type.String({maxLength: 32}),
      fee: Type.Integer({minimum: 0}),
    }), {maxItems: 6}),
    rental: Type.Object({
      active: Type.Boolean(),
      status: Type.Union([
        Type.Literal('none'), Type.Literal('pending'),
        Type.Literal('active'), Type.Literal('returning'),
      ]),
      key: Type.String({maxLength: 32}),
      model: Type.String({maxLength: 32}),
      plate: Type.String({maxLength: 15}),
      startedAt: Type.Integer({minimum: 0}),
      expiresAt: Type.Integer({minimum: 0}),
      truckNetId: Type.Integer({minimum: 0}),
      overageDue: Type.Integer({minimum: 0}),
      debt: Type.Integer({minimum: 0}),
    }),
  }),
  mission: TruckerMissionSchema,
});

export const TruckerActionResultSchema = Type.Object({
  success: Type.Boolean(),
  message: Type.String({maxLength: 256}),
});

export const TruckerServerActionResultSchema = Type.Object({
  success: Type.Boolean(),
  message: Type.String({maxLength: 256}),
  snapshot: TruckerSnapshotSchema,
});

export const TruckerQaScenarioRequestSchema = Type.Object({
  playerSource: Type.Integer({minimum: 1}),
  action: Type.Union([
    Type.Literal('snapshot'),
    Type.Literal('startManualLoading'),
    Type.Literal('startLoading'),
    Type.Literal('positionTutorialDelivery'),
    Type.Literal('startManualUnloading'),
    Type.Literal('runTutorialDelivery'),
    Type.Literal('deleteAssignedVehicle'),
    Type.Literal('cleanup'),
  ]),
});

export const TruckerQaScenarioResponseSchema = Type.Object({
  ok: Type.Boolean(),
  errorCode: Type.String({maxLength: 64}),
  retryable: Type.Boolean(),
  data: Type.Object({
    state: Type.Union([
      Type.Literal('IDLE'),
      Type.Literal('ACTIVE'),
      Type.Literal('LOADING'),
      Type.Literal('IN_TRANSIT'),
      Type.Literal('UNLOADING'),
      Type.Literal('COMPLETED'),
      Type.Literal('CANCELLED'),
    ]),
    replayVerified: Type.Boolean(),
    deleted: Type.Boolean(),
    snapshot: TruckerSnapshotSchema,
  }),
});

export const TruckerNoticeSchema = Type.Object({
  type: TruckerNoticeTypeSchema,
  message: Type.String({minLength: 1, maxLength: 256}),
});
