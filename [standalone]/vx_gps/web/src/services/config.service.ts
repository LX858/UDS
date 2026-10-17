import {inject, injectable, named} from 'inversify';

import {makeAutoObservable} from 'mobx';
import {fetchNui} from '../utils/fetchNui';
import {isEnvBrowser, Sleep} from '../utils/misc';
import {
  defineService,
  ServicesContainer,
  useService,
} from '../utils/servicesContainer';
import {registerAppContribution, AppContribution} from './app/app.extensions';
import {EventsService} from './events/events.service';
import {ScopedLogger} from './log/scopedLogger';
import {DefaultSetting, ISetting} from '../types';
import stringd from 'stringd';

export type IConfigService = ConfigService;
export const IConfigService = defineService<IConfigService>('ConfigService');

export function registerConfigService(container: ServicesContainer) {
  container.registerImpl(IConfigService, ConfigService);
  registerAppContribution(container, ConfigService);
}

@injectable()
class ConfigService implements AppContribution {
  @inject(ScopedLogger)
  @named('ConfigService')
  private logService: ScopedLogger;

  @inject(EventsService)
  private eventsService: EventsService;

  loading = false;

  data: ISetting = DefaultSetting;
  setData(data: ISetting) {
    this.data = data;
  }

  async fetchNui<T>(eventName: string, data: unknown) {
    if (this.loading) return;
    this.loading = true;
    try {
      if (isEnvBrowser()) {
        console.log(eventName, data);
        await Sleep(2000);
        return;
      }
      const response = await fetchNui<T>(eventName, data);
      return response;
    } catch (error: unknown) {
      console.error(error);
    } finally {
      this.loading = false;
    }
  }

  constructor() {
    makeAutoObservable(this);
  }

  async init() {
    this.logService.log('init');
  }

  L = (key: string, args?: {[key: string]: string | number}) => {
    if (this.data.locale[key]) {
      return stringd(this.data.locale[key], args) as string;
    }
    return key;
  };
}

export function useConfigService(): IConfigService {
  return useService(IConfigService);
}
