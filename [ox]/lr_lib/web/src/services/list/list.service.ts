import {inject, injectable, named} from 'inversify';

import {makeAutoObservable} from 'mobx';
import {fetchNui} from '../../utils/fetchNui';
import {isEnvBrowser, Sleep} from '../../utils/misc';
import {
  defineService,
  ServicesContainer,
  useService,
} from '../../utils/servicesContainer';
import {registerAppContribution, AppContribution} from '../app/app.extensions';
import {EventsService} from '../events/events.service';
import {ScopedLogger} from '../log/scopedLogger';
import {IList} from '../../types/list.type';

export type IListService = ListService;
export const IListService = defineService<IListService>('ListService');

export function registerListService(container: ServicesContainer) {
  container.registerImpl(IListService, ListService);
  registerAppContribution(container, ListService);
}

@injectable()
class ListService implements AppContribution {
  @inject(ScopedLogger)
  @named('ListService')
  private logService: ScopedLogger;

  @inject(EventsService)
  private eventsService: EventsService;

  loading = false;

  async fetchNui<T>(eventName: string, data: any) {
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
    } catch (error: any) {
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

  lists: IList[] = [];
}

export function useListService(): IListService {
  return useService(IListService);
}
