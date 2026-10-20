import {inject, injectable, named} from 'inversify';
import {makeAutoObservable, runInAction} from 'mobx';
import {
  DEV_TRADE_CATALOG,
  EMPTY_TRADE_CATALOG,
  ExchangeResponse,
  TradeCatalog,
} from '@/components/trader.data';
import {fetchNui} from '@/utils/fetchNui';
import {isEnvBrowser} from '@/utils/misc';
import {
  ServicesContainer,
  defineService,
  useService,
} from '@/utils/servicesContainer';
import {AppContribution, registerAppContribution} from '../app.extensions';
import {EventsService} from '../../events/events.service';
import {ScopedLogger} from '../../log/scopedLogger';

const normalizeCatalog = (catalog?: Partial<TradeCatalog> | null): TradeCatalog => ({
  chests: Array.isArray(catalog?.chests) ? catalog.chests : [],
  items: Array.isArray(catalog?.items) ? catalog.items : [],
  outfits: Array.isArray(catalog?.outfits) ? catalog.outfits : [],
});

export type ITraderService = TraderService;
export const ITraderService = defineService<ITraderService>('TraderService');

export function registerTraderService(container: ServicesContainer) {
  container.registerImpl(ITraderService, TraderService);
  registerAppContribution(container, TraderService);
}

@injectable()
class TraderService implements AppContribution {
  @inject(ScopedLogger)
  @named('TraderService')
  private logService: ScopedLogger;

  @inject(EventsService)
  private eventsService: EventsService;

  catalog: TradeCatalog = isEnvBrowser()
    ? DEV_TRADE_CATALOG
    : EMPTY_TRADE_CATALOG;
  loading = false;
  exchanging = false;
  error = '';

  constructor() {
    makeAutoObservable(this);
  }

  async init() {
    this.eventsService.subscribe<boolean>('main:setShow', show => {
      if (show) void this.refreshCatalog();
    });
  }

  async refreshCatalog() {
    if (isEnvBrowser()) return this.catalog;

    this.loading = true;
    this.error = '';
    try {
      const catalog = await fetchNui<TradeCatalog>('getCatalog');
      runInAction(() => {
        this.catalog = normalizeCatalog(catalog);
      });
      return catalog;
    } catch (error) {
      const message = 'Không thể tải danh sách quy đổi.';
      this.logService.error(
        error instanceof Error ? error : new Error(message),
        {context: message}
      );
      runInAction(() => {
        this.error = message;
      });
      return null;
    } finally {
      runInAction(() => {
        this.loading = false;
      });
    }
  }

  async exchange(entryId: string, quantity: number): Promise<ExchangeResponse> {
    if (this.exchanging) {
      return {
        success: false,
        code: 'busy',
        message: 'Giao dịch trước đang được xử lý.',
      };
    }

    this.exchanging = true;
    this.error = '';
    try {
      const response = await fetchNui<ExchangeResponse>(
        'exchange',
        {entryId, quantity},
        {
          success: true,
          code: 'success',
          message: 'Vật phẩm đã được thêm vào túi đồ.',
          catalog: this.catalog,
        }
      );
      runInAction(() => {
        if (response.catalog) this.catalog = normalizeCatalog(response.catalog);
        if (!response.success) this.error = response.message;
      });
      return response;
    } catch (error) {
      const response = {
        success: false,
        code: 'network_error',
        message: 'Không thể kết nối tới máy chủ.',
      };
      this.logService.error(
        error instanceof Error ? error : new Error(response.message),
        {context: response.message}
      );
      runInAction(() => {
        this.error = response.message;
      });
      return response;
    } finally {
      runInAction(() => {
        this.exchanging = false;
      });
    }
  }
}

export function useTraderService(): ITraderService {
  return useService(ITraderService);
}
