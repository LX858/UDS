export * from './main/main.boundaries.ts';
export * from './main/main.schemas.ts';
export * from './trucker/trucker.boundaries.ts';
export * from './trucker/trucker.schemas.ts';

import {mainBoundaries} from './main/main.boundaries.ts';
import {truckerBoundaries} from './trucker/trucker.boundaries.ts';

export const moduleBoundaries = Object.freeze({
  main: mainBoundaries,
  trucker: truckerBoundaries,
});
