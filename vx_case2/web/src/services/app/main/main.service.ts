import { inject, injectable, named } from 'inversify';
import { AppContribution, registerAppContribution } from '../app.extensions';
import { ScopedLogger } from '../../log/scopedLogger';
import { ServicesContainer, defineService, useService } from '../../../utils/servicesContainer';
import { EventsService } from '../../events/events.service';
import { makeAutoObservable } from 'mobx';
import { fetchNui } from '../../../utils/fetchNui';

export type Currency = 'coins' | 'cash';

export interface SpinItem {
    id: number;
    label: string;
    type: 'discount' | 'coins' | 'freeSpin';
    value: number;
}

export interface ShopItem {
    id: number;
    name: string;
    label: string;
    image?: string;
    basePrice: number;
    price: number;
    basePriceMoney?: number;
    priceMoney?: number;
}

export interface CaseState {
    coins: number;
    cashBalance: number;
    progress: number;
    milestoneTarget: number;
    spinCredits: number;
    canSpin: boolean;
    pendingDiscount?: number;
    shopItems: ShopItem[];
    refreshCost: number;
    maxPurchaseQuantity: number;
    milestoneClaimed: boolean;
    actionLockedUntil: number;
    serverTime: number;
    spinRewards: SpinItem[];
}

export interface MutationResponse<TResult = unknown> {
    ok: boolean;
    message?: string;
    state?: CaseState;
    result?: TResult;
}

export interface SpinResult {
    index: number;
    reward: SpinItem;
}

interface PurchaseResult {
    itemId: number;
    quantity: number;
    currency: Currency;
    total: number;
    milestoneDelivered?: boolean;
}

const mockItems: ShopItem[] = [
    { id: 1, name: 'skin_babytree_2026', label: 'SKIN BABY TREE 2026', basePrice: 1500, price: 1500, basePriceMoney: 1500000, priceMoney: 1500000 },
    { id: 2, name: 'skin_rich_2026', label: 'SKIN RICH 2026', basePrice: 1500, price: 1500, basePriceMoney: 1500000, priceMoney: 1500000 },
    { id: 3, name: 'the_outfit', label: 'THẺ TRANG PHỤC', basePrice: 500, price: 500, basePriceMoney: 500000, priceMoney: 500000 },
    { id: 4, name: 'the_skin', label: 'THẺ SKIN', basePrice: 650, price: 650, basePriceMoney: 650000, priceMoney: 650000 },
    { id: 5, name: 'the_trung_thu', label: 'THẺ TRUNG THU', basePrice: 350, price: 350 },
    { id: 6, name: 'banh_trung_thu', label: 'BÁNH TRUNG THU', basePrice: 99, price: 99 },
];

const mockSpinItems: SpinItem[] = [
    { id: 1, label: '-50%', type: 'discount', value: 50 },
    { id: 2, label: '29 XU', type: 'coins', value: 29 },
    { id: 3, label: 'QUA LƯỢT', type: 'freeSpin', value: 1 },
    { id: 4, label: '99 XU', type: 'coins', value: 99 },
    { id: 5, label: '-10%', type: 'discount', value: 10 },
    { id: 6, label: 'QUA LƯỢT', type: 'freeSpin', value: 1 },
    { id: 7, label: '-80%', type: 'discount', value: 80 },
    { id: 8, label: '-30%', type: 'discount', value: 30 },
];

const createMockState = (): CaseState => ({
    coins: 299,
    cashBalance: 2_000_000,
    progress: 299,
    milestoneTarget: 3500,
    spinCredits: 1,
    canSpin: true,
    shopItems: mockItems,
    refreshCost: 5,
    maxPurchaseQuantity: 999,
    milestoneClaimed: false,
    actionLockedUntil: 0,
    serverTime: Math.floor(Date.now() / 1000),
    spinRewards: mockSpinItems,
});

let fallbackRequestSequence = 0;
const requestId = () => {
    if (typeof crypto !== 'undefined' && crypto.randomUUID) return crypto.randomUUID();
    fallbackRequestSequence += 1;
    return `${Date.now()}-vx-case2-${fallbackRequestSequence}`;
};

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

    show = import.meta.env.DEV;
    showNotes = false;
    rewards?: string;
    state: CaseState = createMockState();
    selectedItem?: ShopItem;
    selectDialogOpen = false;
    quantity = 1;
    currency: Currency = 'coins';
    loadingAction?: 'state' | 'spin' | 'refresh' | 'purchase';
    private receivedAt = Date.now();
    private clock = Date.now();

    constructor() {
        makeAutoObservable(this);
    }

    async init() {
        this.logService.log('init');
        this.eventsService.subscribe<boolean>('main:setShow', this.setShow.bind(this));
        this.eventsService.subscribe<CaseState>('main:setState', this.setState.bind(this));
        window.setInterval(() => { this.clock = Date.now(); }, 250);
    }

    get spinItems() {
        return this.state.spinRewards;
    }

    get actionLocked() {
        const estimatedServerTime = this.state.serverTime + (this.clock - this.receivedAt) / 1000;
        return estimatedServerTime < this.state.actionLockedUntil;
    }

    get canInteract() {
        return !this.loadingAction && !this.actionLocked;
    }

    get canSpin() {
        return this.state.spinCredits > 0 && this.state.pendingDiscount === undefined && !this.actionLocked;
    }

    get maxQuantity() {
        if (!this.selectedItem) return 1;
        const unitPrice = this.currency === 'cash' ? this.selectedItem.priceMoney : this.selectedItem.price;
        const balance = this.currency === 'cash' ? this.state.cashBalance : this.state.coins;
        if (!unitPrice || unitPrice <= 0) return 1;
        return Math.max(1, Math.min(this.state.maxPurchaseQuantity, Math.floor(balance / unitPrice)));
    }

    setShow(show: boolean) {
        this.show = show;
        if (!show) {
            this.closePurchase();
            this.clearRewards();
            this.showNotes = false;
        }
    }

    setState(state: CaseState) {
        if (!state) return;
        this.state = state;
        this.receivedAt = Date.now();
        this.clock = Date.now();
        if (this.selectedItem) {
            this.selectedItem = state.shopItems.find(item => item.id === this.selectedItem?.id);
            if (!this.selectedItem) this.closePurchase();
        }
    }

    async loadState() {
        if (this.loadingAction) return;
        this.loadingAction = 'state';
        try {
            const response = await fetchNui<MutationResponse<never>>('GetCaseState', {}, { ok: true, state: createMockState() });
            if (response.state) this.setState(response.state);
            return response;
        } finally {
            this.loadingAction = undefined;
        }
    }

    async spin() {
        if (!this.canInteract || !this.canSpin || this.spinItems.length === 0) {
            return { ok: false, message: 'Bạn chưa thể quay lúc này' } as MutationResponse<SpinResult>;
        }
        this.loadingAction = 'spin';
        try {
            const mockIndex = 0;
            const response = await fetchNui<MutationResponse<SpinResult>>('Spin', { requestId: requestId() }, {
                ok: true,
                state: { ...this.state, spinCredits: 0, canSpin: false, actionLockedUntil: Math.floor(Date.now() / 1000) + 12 },
                result: { index: mockIndex, reward: this.spinItems[mockIndex] },
            });
            if (response.state) this.setState(response.state);
            return response;
        } finally {
            this.loadingAction = undefined;
        }
    }

    async refreshItems() {
        if (!this.canInteract) return;
        this.loadingAction = 'refresh';
        try {
            const response = await fetchNui<MutationResponse>('RefreshItems', { requestId: requestId() }, {
                ok: true,
                state: { ...this.state, coins: Math.max(0, this.state.coins - this.state.refreshCost) },
            });
            if (response.state) this.setState(response.state);
            return response;
        } finally {
            this.loadingAction = undefined;
        }
    }

    openPurchase(item: ShopItem) {
        if (!this.canInteract) return;
        this.selectedItem = item;
        this.currency = 'coins';
        this.quantity = 1;
        this.selectDialogOpen = true;
    }

    closePurchase() {
        this.selectDialogOpen = false;
        this.selectedItem = undefined;
        this.quantity = 1;
        this.currency = 'coins';
    }

    setCurrency(currency: Currency) {
        if (currency === 'cash' && this.selectedItem?.priceMoney === undefined) return;
        this.currency = currency;
        this.quantity = Math.min(this.quantity, this.maxQuantity);
    }

    setQuantity(value: number) {
        if (!Number.isFinite(value)) return;
        this.quantity = Math.max(1, Math.min(this.state.maxPurchaseQuantity, Math.floor(value)));
    }

    setMaxQuantity() {
        this.quantity = this.maxQuantity;
    }

    async purchase() {
        if (!this.selectedItem || !this.canInteract) return;
        this.loadingAction = 'purchase';
        try {
            const response = await fetchNui<MutationResponse<PurchaseResult>>('Purchase', {
                itemId: this.selectedItem.id,
                quantity: this.quantity,
                currency: this.currency,
                requestId: requestId(),
            }, {
                ok: true,
                state: { ...this.state, spinCredits: this.state.spinCredits + 1 },
                result: { itemId: this.selectedItem.id, quantity: this.quantity, currency: this.currency, total: 0 },
            });
            if (response.state) this.setState(response.state);
            if (response.ok) {
                this.closePurchase();
                if (response.result?.milestoneDelivered) this.setRewards('PHẦN THƯỞNG MỐC 3500 XU');
            }
            return response;
        } finally {
            this.loadingAction = undefined;
        }
    }

    toggleNotes(value: boolean) {
        this.showNotes = value;
    }

    setRewards(rewards: string) {
        this.rewards = rewards;
    }

    clearRewards() {
        this.rewards = undefined;
    }
}

export function useMainService(): IMainService {
    return useService(IMainService);
}
