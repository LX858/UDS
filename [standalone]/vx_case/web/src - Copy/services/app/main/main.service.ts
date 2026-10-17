import {inject, injectable, named} from 'inversify';
import {AppContribution, registerAppContribution} from '../app.extensions';
import {ScopedLogger} from '../../log/scopedLogger';
import {
  ServicesContainer,
  defineService,
  useService,
} from '../../../utils/servicesContainer';
import {EventsService} from '../../events/events.service';
import { makeAutoObservable } from 'mobx';
import { isEnvBrowser } from '@/utils/misc';
import { fetchNui } from '../../../utils/fetchNui';
import { showNotify } from '../../../utils/toast';

export type IMainService = MainService;
export const IMainService = defineService<IMainService>('MainService');

export interface IReward {
  name: string;
  label?: string;
  type: string;
  amount?: number;
  metadata?: {
    imageurl?: string;
    [key: string]: unknown;
  };
  isReward?: boolean;
}

export function registerMainService(container: ServicesContainer) {
  container.registerImpl(IMainService, MainService);
  registerAppContribution(container, MainService);
}

@injectable()
class MainService implements AppContribution {
  @inject(ScopedLogger)
  @named('MainService')
  private logService: ScopedLogger;
  @inject(EventsService)
  private eventsService: EventsService;

  constructor() {
    makeAutoObservable(this);
  }

  show = import.meta.env.DEV ? true : false;
  count: number = isEnvBrowser() ? 999 : 0;
  state: 'idle' | 'opening' | 'reward' = 'idle';
  items: IReward[] = isEnvBrowser() ? this.generateRandomRewards(100) : [];
  spinningItems: IReward[] = [];
  result: IReward[] = [];
  mutiplier: number = 1;

  async init() {
    this.logService.log('init');
    this.eventsService.subscribe('main:setShow', this.setShow.bind(this));
    this.eventsService.subscribe('main:setItems', this.setItems.bind(this));
    this.eventsService.subscribe('main:setCount', this.setCount.bind(this));
    this.eventsService.subscribe('main:showNotify', (message: string) => {
      showNotify('Thông Báo', message);
    });
  }

  changeMultiplier() {
    this.mutiplier = this.mutiplier === 1 ? 5 : 1;
  }
  setShow(show: boolean) {
    this.show = show;
  }

  setItems(items: IReward[]) {
    console.log('setItems', items);
    this.items = items;
  }

  setCount(count: number) {
    this.count = Number.isFinite(count) ? Math.max(0, count) : 0;
  }

  private generateRandomRewards(count: number): IReward[] {
    const names = ['the_pvp', 'the_pvp', 'the_pvp', 'the_pvp', 'the_pvp', 'the_pvp'];
    return Array.from({length: count}, (_, index) => {
      const name = names[Math.floor(Math.random() * names.length)];
      return {
        name,
        label: `${name.charAt(0).toUpperCase()}${name.slice(1)} ${index + 1}`,
        type: 'item',
        amount: Math.floor(Math.random() * 100) + 1,
      };
    });
  }

  private generateFakeItems(reward: IReward) {
    const items = [...this.items];
    for (let index = 0; index < 125; index += 1) {
      items.push(index === 80 ? {...reward, isReward: true} : this.items[Math.floor(Math.random() * this.items.length)]);
    }
    return items.filter(Boolean);
  }

  async openChest() {
    if (this.state !== 'idle' || this.items.length === 0) return null;

    const result = await fetchNui<IReward[]>('GetResult', {multiplier: this.mutiplier}, [this.items[0]]);
    if (!Array.isArray(result) || result.length === 0) return null;
    this.result = result;
    this.spinningItems = this.generateFakeItems(result[0]);
    this.state = 'opening';
    return this.spinningItems;
  }

  finishOpening() {
    if (this.state === 'opening') this.state = 'reward';
  }

  spinAgain() {
    if (this.state !== 'reward') return;
    this.result = [];
    this.spinningItems = [];
    this.state = 'idle';
  }

  async closeUI() {
    if (this.state === 'opening') return;
    this.state = 'idle';
    this.show = false;
    await fetchNui('close', undefined, true);
  }
}

export function useMainService(): IMainService {
  return useService(IMainService);
}
