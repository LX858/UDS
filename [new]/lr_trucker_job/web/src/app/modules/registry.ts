import {MainStore} from './main/main.store';
import {TruckerStore} from './trucker/trucker.store';

export const storeModules = {
  main: MainStore,
  trucker: TruckerStore,
} as const;
