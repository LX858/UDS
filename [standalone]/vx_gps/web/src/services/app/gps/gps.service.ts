import { inject, injectable, named } from 'inversify';
import { AppContribution, registerAppContribution } from '../app.extensions';
import { ScopedLogger } from '../../log/scopedLogger';
import {
    ServicesContainer,
    defineService,
    useService,
} from '../../../utils/servicesContainer';
import { EventsService } from '../../events/events.service';
import { makeAutoObservable } from 'mobx';
import { fetchNui } from '@/utils/fetchNui';
import { isEnvBrowser } from '@/utils/misc';

export type IGpsService = GpsService;
export const IGpsService = defineService<IGpsService>('GpsService');

export function registerGpsService(container: ServicesContainer) {
    container.registerImpl(IGpsService, GpsService);
    registerAppContribution(container, GpsService);
}

@injectable()
class GpsService implements AppContribution {
    @inject(ScopedLogger)
    @named('GpsService')
    private logService: ScopedLogger;
    @inject(EventsService)
    private eventsService: EventsService;

    ws: WebSocket | null = null;
    reconnectDelay = 1000;
    reconnectTimeout: any = null;
    lastRegisterData: any = null;
    clients: { player_id: string, player_name: string, faction: string, ping?: number, position: { x: number, y: number, z: number, w: number }, enabled?: boolean }[] = [];
    enabled: boolean = true;

    constructor() {
        makeAutoObservable(this);
    }

    async init() {
        this.logService.log('init');
        this.connectWS();
        if (isEnvBrowser()) {
            this.registerGpsClient({
                globalName: 'ambulance',
                playerId: 1,
                playerName: 'Administrator'
            });
        }
        window.addEventListener("message", this.onNuiMessage);
    }

    private updateQueue = new Map<string, any>();
    private flushTimer: number | null = null;
    private wsGeneration = 0;

    private queueClientUpdate(msg: any) {
        const playerId = String(msg.player_id);
        this.updateQueue.set(playerId, {
            ...msg,
            player_id: playerId,
        });

        if (this.flushTimer) return;

        this.flushTimer = window.setTimeout(() => {
            const updates = Array.from(this.updateQueue.values());
            this.updateQueue.clear();
            this.flushTimer = null;

            if (updates.length > 0 && !isEnvBrowser()) {
                fetchNui("ClientUpdateBatch", { updates }).catch(() => { });
            }
        }, 150);
    }

    dispose() {
        window.removeEventListener("message", this.onNuiMessage);

        if (this.reconnectTimeout) clearTimeout(this.reconnectTimeout);

        if (this.ws) {
            this.ws.onclose = null;
            this.ws.close();
        }
    }

    onToggleGps() {
        this.enabled = !this.enabled;
        fetchNui("Gps:Toggle", { enabled: this.enabled });
        if (!this.enabled) {
            this.clients = [];
            this.ws?.close();
        } else {
            this.connectWS();
        }
    }


    togglePlayer(player_id: string) {
        const client = this.clients.find(c => c.player_id === player_id);
        if (client) {
            client.enabled = !client.enabled;
        }
    }

    connectWS = () => {
        if (
            this.ws &&
            (this.ws.readyState === WebSocket.OPEN ||
                this.ws.readyState === WebSocket.CONNECTING)
        ) {
            return;
        }
        this.logService.log("Connecting WebSocket...");
        const generation = ++this.wsGeneration;
        this.ws = new WebSocket("wss://gps.viegta5.net/ws");

        this.ws.onopen = () => {
            this.logService.log("WebSocket Connected!");
            this.reconnectDelay = 1000;

            if (this.lastRegisterData) {
                this.logService.log("Re-registering:", this.lastRegisterData);
                this.send(this.lastRegisterData);
            }
        };

        this.ws.onmessage = (event) => {
            if (!this.enabled) {
                return;
            }
            try {
                const msg = JSON.parse(event.data);

                switch (msg.action) {
                    case "new_player":
                        if (!isEnvBrowser()) {
                            console.log("Registering new player with server:", JSON.stringify(msg), typeof msg);
                            fetchNui("ClientRegistered", msg);
                        }
                        this.newClient({
                            player_id: msg.player_id,
                            player_name: msg.player_name || 'Unknown',
                            faction: msg.faction
                        });
                        this.logService.log("New player registered:", msg.player_id, "name:", msg.player_name, "faction:", msg.faction);
                        break;
                    case "update":
                        // this.logService.log("Player updated:", msg.player_id);
                        if (!isEnvBrowser()) {
                            const client = this.clients.find(c => c.player_id === msg.player_id);
                            if (client && client.enabled === false) {
                                return;
                            }
                            const ping = msg.server_time - msg.last_update;
                            this.queueClientUpdate(msg);
                            this.clients = this.clients.map(c => {
                                if (c.player_id === msg.player_id) {
                                    return { ...c, position: msg.position, ping };
                                }
                                return c;
                            });
                        }
                        break;
                    case "remove_player":
                        this.logService.log("Player removed:", JSON.stringify(msg), typeof msg);
                        this.clients = this.clients.filter(c => c.player_id !== msg.player_id);
                        if (!isEnvBrowser()) {
                            fetchNui("ClientRemoved", msg);
                        }
                        break;
                    default:
                        this.logService.log("Unknown message action:", JSON.stringify(msg), typeof msg);
                        break;
                }
            } catch (e) {
                this.logService.log("Error parsing WebSocket message:", e);
                return;
            }

        };

        this.ws.onclose = () => {
            if (!this.enabled || generation !== this.wsGeneration) return;

            this.reconnectDelay = Math.min(this.reconnectDelay * 1.5, 10000);
            this.reconnectTimeout = window.setTimeout(this.connectWS, this.reconnectDelay);
        };

        this.ws.onerror = () => {
            this.logService.log("WebSocket error, closing...");
            this.ws?.close();
        };
    };

    newClient(data: { player_id: string | number, player_name: string, faction: string }) {
        const playerId = String(data.player_id);

        if (this.clients.find(c => c.player_id === playerId)) {
            return;
        }

        this.clients.push({
            player_id: playerId,
            player_name: data.player_name,
            faction: data.faction,
            position: { x: 0, y: 0, z: 0, w: 0 },
            enabled: true,
        });
    }

    send(data: any) {
        if (this.ws && this.ws.readyState === WebSocket.OPEN) {
            this.ws.send(JSON.stringify(data));
        }
    }

    onNuiMessage = (e: MessageEvent<any>) => {
        const { event, data } = e.data;

        if (event === "GlobalPosition:Register") {
            this.registerGpsClient({
                globalName: data.globalName,
                playerId: data.playerId,
                playerName: data.playerName || 'Unknown',
            });
        } else if (event === "GlobalPosition:UpdatePlayer") {
            this.send({
                action: "update",
                player_id: data.src,
                position: data.coords,
                last_update: Date.now(),
            });
        }
    };

    registerGpsClient(data: { globalName: string, playerId: any, playerName: string }) {
        const packet = {
            action: "register",
            faction: data.globalName,
            player_id: data.playerId,
            player_name: data.playerName,
        };

        this.lastRegisterData = packet;
        this.send(packet);
        this.logService.log("Registered GPS client:", JSON.stringify(packet, null, 2));
    }

}

export function useGpsService(): IGpsService {
    return useService(IGpsService);
}
