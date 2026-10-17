export type TradeCost = {
  item: string;
  label: string;
  owned: number;
  required: number;
};

export type TradeEntry = {
  id: string;
  name: string;
  image: string;
  costs: TradeCost[];
  rewardAmount?: number;
  maxQuantity?: number;
  special?: boolean;
  vehicleModel?: string;
  badge?: string;
  gender?: 'male' | 'female';
};

export type TradeCatalog = {
  chests: TradeEntry[];
  items: TradeEntry[];
  outfits: TradeEntry[];
};

export type ExchangeResponse = {
  success: boolean;
  code: string;
  message: string;
  catalog?: TradeCatalog;
};

export const EMPTY_TRADE_CATALOG: TradeCatalog = {
  chests: [],
  items: [],
  outfits: [],
};

export const getItemImage = (name: string) =>
  `https://raw.githubusercontent.com/xuannguyen995/prime_item/refs/heads/main/${name}.webp`;

// Browser-only fixtures keep the Vite preview useful. FiveM always loads the
// authoritative catalog and owned counts from the Lua server.
export const DEV_TRADE_CATALOG: TradeCatalog = {
  chests: [
    {
      id: 'mid-autumn-box',
      name: 'Hòm Trung Thu',
      image: getItemImage('hom_trung_thu'),
      rewardAmount: 1,
      maxQuantity: 1,
      costs: [
        {item: 'the_trung_thu', label: 'Thẻ Trung Thu', owned: 18, required: 10},
      ],
    },
  ],
  items: [
    {
      id: 'skin-babytree-2026',
      name: 'Skin Babytree 2026',
      image: getItemImage('skin_babytree_2026'),
      rewardAmount: 1,
      maxQuantity: 1,
      costs: [{item: 'the_skin', label: 'Thẻ Skin', owned: 25, required: 20}],
    },
    {
      id: 'skin-rich-2026',
      name: 'Skin Rich 2026',
      image: getItemImage('skin_rich_2026'),
      rewardAmount: 1,
      maxQuantity: 1,
      costs: [{item: 'the_skin', label: 'Thẻ Skin', owned: 25, required: 20}],
    },
    {
      id: 'vehicle-r35',
      name: 'Vé Đổi Xe R35',
      image: './assets/vedoixe.png',
      rewardAmount: 1,
      maxQuantity: 1,
      special: true,
      vehicleModel: 'r35',
      costs: [{item: 'the_outfit', label: 'Thẻ Trang Phục', owned: 999, required: 999}],
    },
    {
      id: 'vehicle-rongngao',
      name: 'Vé Đổi Xe Rồng Ngáo',
      image: './assets/rongngao.png',
      rewardAmount: 1,
      maxQuantity: 1,
      special: true,
      vehicleModel: 'rongngao',
      costs: [{item: 'the_outfit', label: 'Thẻ Trang Phục', owned: 999, required: 399}],
    },
  ],
  outfits: [],
};

export const canExchangeEntry = (entry: TradeEntry) =>
  entry.costs.every(cost => cost.owned >= cost.required);

export const getMaxExchangeQuantity = (entry: TradeEntry) => {
  const materialLimit = entry.costs.reduce(
    (limit, cost) => Math.min(limit, Math.floor(cost.owned / cost.required)),
    Number.MAX_SAFE_INTEGER
  );
  const serverLimit = Number.isInteger(entry.maxQuantity)
    ? Math.max(0, entry.maxQuantity ?? 0)
    : 999;

  return Math.max(0, Math.min(materialLimit, serverLimit));
};
