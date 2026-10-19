import {State, Store} from '@lr/nui-store';
import type {ContractStatic} from '@lr/contracts';
import {
  TruckerSettingsSchema,
  TruckerSnapshotSchema,
  TruckerVisibilitySchema,
} from '@lr/contracts/authoring/trucker';

export const emptyTruckerSnapshot: ContractStatic<typeof TruckerSnapshotSchema> = {
  player: {source: 0, citizenId: '', name: '', cash: 0, bank: 0, level: 1, xp: 0},
  orderPage: {filter: 'all', page: 1, pageSize: 20, total: 0, items: []},
  business: {
    active: false,
    sourceOnline: false,
    businessId: '',
    label: '',
    balance: 0,
    distanceKm: 0,
    feeBase: 0,
    feePerKm: 0,
    feePerPackage: 0,
    feeMaximum: 0,
    feeRate: 0,
    catalog: [],
    orders: [],
  },
  fleet: {
    bank: 0,
    ownedVehicles: [],
    rentalOptions: [],
    rental: {
      active: false, status: 'none', key: '', model: '', plate: '',
      startedAt: 0, expiresAt: 0, truckNetId: 0, overageDue: 0, debt: 0,
    },
  },
  mission: {
    active: false,
    status: 'idle',
    id: '',
    routeIndex: 0,
    deliveryRouteIndex: 0,
    name: '',
    itemLabel: '',
    destination: '',
    logisticsUnits: 0,
    vehicleMode: '',
    vehicleModel: '',
    ownedVehicleId: 0,
    vehiclePlate: '',
    step: 0,
    packageAmount: 0,
    loaded: 0,
    delivered: 0,
    reward: 0,
    xp: 0,
    truckNetId: 0,
    trailerNetId: 0,
    escortNetId: 0,
    packages: [],
    orderKind: 'market',
    cargoMode: 'pallets',
    businessId: '',
    lines: [],
    fuelLiters: 0,
    fuelProgress: 0,
    pickupCoords: {x: 0, y: 0, z: 0, w: 0},
    deliveryCoords: {x: 0, y: 0, z: 0, w: 0},
  },
};

@Store({id: 'trucker'})
export class TruckerStore {
  @State(TruckerVisibilitySchema, {visible: false})
  accessor visibility!: ContractStatic<typeof TruckerVisibilitySchema>;

  @State(TruckerSettingsSchema, {locale: {}, dev: false})
  accessor settings!: ContractStatic<typeof TruckerSettingsSchema>;

  @State(TruckerSnapshotSchema, emptyTruckerSnapshot)
  accessor snapshot!: ContractStatic<typeof TruckerSnapshotSchema>;

  L(key: string, args?: Record<string, string | number>) {
    const template = this.settings.locale[key] ?? key;
    if (!args) return template;
    return Object.entries(args).reduce(
      (value, [argKey, argValue]) =>
        value.replaceAll(`:{${argKey}}`, String(argValue)),
      template
    );
  }
}
