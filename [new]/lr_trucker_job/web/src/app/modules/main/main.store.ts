import type {ContractStatic} from '@lr/contracts';
import {MainGameSchema} from '@lr/contracts/authoring/main';
import {State, Store} from '@lr/nui-store';

@Store({id: 'main'})
export class MainStore {
  @State(MainGameSchema, {playerName: '', playerId: ''})
  accessor game!: ContractStatic<typeof MainGameSchema>;
}
