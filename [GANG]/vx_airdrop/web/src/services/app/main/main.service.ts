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
import { fetchNui } from '../../../utils/fetchNui';
import { isEnvBrowser } from '@/utils/misc';

export type IMainService = MainService;
export const IMainService = defineService<IMainService>('MainService');

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

  show = isEnvBrowser() ? true : false;
  now = performance.now() / 1000;
  alert?: { roundId: string; endsAt: number };
  myTeam: any = "B";
  gameData?: {
    team1Score: number;
    team2Score: number;
    endsAt: number;
    overtime: boolean;
    team: 'A' | 'B';
  } = isEnvBrowser() ? {
    team1Score: 0,
    team2Score: 0,
    endsAt: this.now + 60,
    overtime: false,
    team: 'A',
  } : undefined;
  weapons?: { id: string; name: string; image: string }[];
  result?: 'win' | 'lose';

  async init() {
    this.logService.log('init');
    this.eventsService.subscribe('main:setShow', this.setShow.bind(this));
    this.eventsService.subscribe('airdrop:registration', this.setAlert.bind(this));
    this.eventsService.subscribe('airdrop:score', this.setScore.bind(this));
    this.eventsService.subscribe('airdrop:weapons', this.setWeapons.bind(this));
    this.eventsService.subscribe('airdrop:result', this.setResult.bind(this));
    this.eventsService.subscribe('airdrop:myTeam', this.setMyTeam.bind(this));
    window.setInterval(() => { this.now = performance.now() / 1000; }, 250);
  }

  setShow(show: boolean) {
    this.show = show;
  }

  setAlert(alert?: { roundId: string; remainingSeconds: number }) {
    this.now = performance.now() / 1000;
    this.alert = alert ? {
      roundId: alert.roundId,
      endsAt: this.now + Math.max(0, alert.remainingSeconds),
    } : undefined;
  }

  setMyTeam(team: 1 | 2) {
    this.myTeam = team;
  }

  setScore(data?: Omit<NonNullable<MainService['gameData']>, 'endsAt'> & { remainingSeconds: number }) {
    this.now = performance.now() / 1000;
    this.gameData = data ? {
      team1Score: data.team1Score,
      team2Score: data.team2Score,
      overtime: data.overtime,
      team: data.team,
      endsAt: this.now + Math.max(0, data.remainingSeconds),
    } : undefined;
  }

  setWeapons(weapons?: MainService['weapons']) {
    this.weapons = weapons || undefined;
  }

  setResult(result?: 'win' | 'lose') {
    this.result = result || undefined;
  }

  async chooseWeapon(weaponId: string) {
    await fetchNui('chooseWeapon', { weaponId });
  }
}

export function useMainService(): IMainService {
  return useService(IMainService);
}
