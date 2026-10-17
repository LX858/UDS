import {injectable, inject, named} from 'inversify';
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
import msgpack from 'msgpack-lite';

export type IRelayService = RelayService;
export const IRelayService = defineService<IRelayService>('RelayService');

export function registerRelayService(container: ServicesContainer) {
  container.registerImpl(IRelayService, RelayService);
  registerAppContribution(container, RelayService);
}

const codec = msgpack.createCodec({
  uint8array: true,
  int64: true,
  binarraybuffer: true,
});

const _pack = (data: any) => msgpack.encode(data, {codec});
const _unpack = (data: any) => msgpack.decode(new Uint8Array(data), {codec});

@injectable()
class RelayService implements AppContribution {
  @inject(ScopedLogger)
  @named('RelayService')
  private logService: ScopedLogger;

  @inject(EventsService)
  private eventsService: EventsService;

  loading = false;
  webSocket: WebSocket | null = null;

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

  id: number = isEnvBrowser() ? 112 : 0;
  token: string = isEnvBrowser()
    ? 'uCVup1qpfsG3EyVJb5KYv6685xWZAAfEmxgSaaArjn6r9Ua8dEG6qNv0xUZPu2nG'
    : '';
  url: string = isEnvBrowser() ? 'ws://localhost:1108/client/ws' : '';
  server: string = isEnvBrowser() ? 'test-lorraxs' : '';
  #pingInterval: NodeJS.Timeout | null = null;

  constructor() {
    makeAutoObservable(this);
  }

  async init() {
    this.logService.log('init');
    if (isEnvBrowser()) {
      this.connect();
      setInterval(() => {
        this.send('testevent', btoa('test'));
      }, 5000);
    }
    this.eventsService.subscribe<{
      eventName: string;
      buffer: string;
    }>('WsTriggerServerEvent', ({eventName, buffer}) => {
      this.send(eventName, buffer);
    });
    this.eventsService.subscribe<{
      playerId: number;
      url: string;
      token: string;
      server: string;
    }>('WsConnect', data => {
      this.id = data.playerId;
      this.url = data.url;
      this.token = data.token;
      this.server = data.server;
      this.connect();
    });
  }

  connect() {
    if (this.webSocket) {
      this.webSocket.close();
    }
    this.webSocket = new WebSocket(
      `${this.url}?id=${this.id}&token=${this.token}&server=${this.server}`
    );
    this.webSocket.onopen = () => {
      console.log('WebSocket connected');
      fetchNui('onWsOpen');
    };
    this.webSocket.onmessage = async (event: MessageEvent<Blob>) => {
      const buffer = await event.data.arrayBuffer();
      /* const data = _unpack(buffer); */
      const b64 = btoa(String.fromCharCode(...new Uint8Array(buffer)));
      /* console.log('WebSocket message', b64);
      console.log('WebSocket message', event.data); */
      fetchNui('onWsMessage', b64);
    };
    this.webSocket.onclose = ev => {
      console.log('WebSocket closed', ev.code, ev.reason);
      setTimeout(() => {
        this.connect();
      }, 1000);
    };
  }

  send(eventName: string, buffer: string) {
    if (!this.webSocket) return;
    const data = [eventName, buffer];
    const packedData = _pack(data);
    this.webSocket.send(packedData);
  }
}

export function useRelayService(): IRelayService {
  return useService(IRelayService);
}
