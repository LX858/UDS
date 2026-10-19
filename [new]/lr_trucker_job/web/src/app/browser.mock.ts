import {NUI_VERSION} from '../nui/contracts';
import {NuiBrowserMock} from '../nui/runtime';
import {emptyTruckerSnapshot} from './modules/trucker/trucker.store';

const rentalKeys = ['mule', 'benson', 'pounder', 'hauler', 'packer', 'phantom'] as const;
function previewRentalRewards(reward: number) {
  return rentalKeys.map(key => ({key, reward}));
}

export function createDefaultBrowserMock(): NuiBrowserMock {
  return {
    rpc: {
      trucker: {
        close: async () => ({success: true, message: ''}),
        refresh: async () => ({success: true, message: 'Đã cập nhật'}),
        acceptOrder: async () => ({success: true, message: 'Đã nhận đơn'}),
        cancelMission: async () => ({success: true, message: 'Đã hủy nhiệm vụ'}),
        upgradeVehicle: async () => ({success: true, message: 'Đã nâng cấp đầu kéo'}),
        getBusinessContext: async () => ({success: true, message: ''}),
        listOrderBoard: async () => ({success: true, message: ''}),
        createBusinessOrder: async () => ({success: true, message: 'Đã tạo đơn giao nguyên liệu'}),
        cancelBusinessOrder: async () => ({success: true, message: 'Đã hủy đơn'}),
      },
    },
    boot: dispatch => {
      dispatch({
        version: NUI_VERSION,
        module: 'main',
        kind: 'state.snapshot',
        name: 'game',
        payload: {playerName: 'Browser Player', playerId: 'preview'},
        revision: 1,
      });
      dispatch({
        version: NUI_VERSION,
        module: 'trucker',
        kind: 'state.snapshot',
        name: 'visibility',
        payload: {visible: true},
        revision: 1,
      });
      dispatch({
        version: NUI_VERSION,
        module: 'trucker',
        kind: 'state.snapshot',
        name: 'settings',
        payload: {
          locale: {
            close: 'Đóng', transport: 'Vận chuyển hàng', available_orders: 'Đơn hàng hiện có',
            accept: 'Nhận đơn', cancel: 'Hủy nhiệm vụ', reward: 'Thưởng',
            packages: 'Kiện hàng', level: 'Cấp độ', refresh: 'Làm mới', no_orders: 'Chưa có đơn hàng',
            mission_progress: 'Tiến độ vận chuyển',
            cash: 'Tiền mặt', xp: 'Kinh nghiệm', step_1: 'Lái xe đến điểm nhận hàng',
            logistics_units: 'Đơn vị logistics', price_per_lu: 'Giá/LU', market_bonus: 'Thưởng thị trường',
            market_shortage: 'Khan hiếm', market_balanced: 'Cân bằng', market_surplus: 'Dư cung',
            route_busy: 'Tuyến đang bận', stock_low: 'Kho không đủ hàng',
            step_2: 'Đậu rơ-moóc vào vị trí nhận hàng', step_3: 'Dùng xe nâng đưa hàng lên rơ-moóc',
            step_4: 'Lái xe đến điểm giao hàng', step_5: 'Đậu rơ-moóc vào vị trí giao hàng',
            step_6: 'Dùng xe nâng đưa hàng xuống bãi', step_7: 'Trả xe và hoàn thành nhiệm vụ',
          },
          dev: true,
        },
        revision: 1,
      });
      dispatch({
        version: NUI_VERSION,
        module: 'trucker',
        kind: 'state.snapshot',
        name: 'snapshot',
        payload: {
          ...emptyTruckerSnapshot,
          player: {source: 28, citizenId: 'PREVIEW28', name: 'Nguyễn Tài Xế', cash: 125000, bank: 725000, level: 7, xp: 6450},
          business: new URLSearchParams(window.location.search).has('procurement') ? {
            active: true,
            sourceOnline: true,
            businessId: 'restaurant_shop',
            label: 'Quán ăn',
            balance: 250000,
            distanceKm: 4.8,
            feeBase: 0,
            feePerKm: 0,
            feePerPackage: 0,
            feeMaximum: 0,
            feeRate: 10,
            catalog: [
              {itemId: 'coconut', label: 'Dừa', category: 'traicay', unitPrice: 400, available: 48, unitsPerPackage: 12, destinationMultiplier: 1, destinationUnit: 'item', destinationItemId: 'dua_soche', destinationLabel: 'Dừa sơ chế'},
              {itemId: 'luami', label: 'Lúa mì', category: 'traicay', unitPrice: 74, available: 0, unitsPerPackage: 12, destinationMultiplier: 1, destinationUnit: 'item', destinationItemId: 'gao', destinationLabel: 'Gạo'},
              {itemId: 'conheo', label: 'Heo', category: 'nuoithu', unitPrice: 600, available: 120, unitsPerPackage: 12, destinationMultiplier: 1, destinationUnit: 'item', destinationItemId: 'conheo', destinationLabel: 'Heo'},
              {itemId: 'conbo', label: 'Bò', category: 'nuoithu', unitPrice: 800, available: 80, unitsPerPackage: 12, destinationMultiplier: 1, destinationUnit: 'item', destinationItemId: 'conbo', destinationLabel: 'Bò'},
              {itemId: 'luanuoc', label: 'Lúa nước', category: 'traicay', unitPrice: 300, available: 160, unitsPerPackage: 12, destinationMultiplier: 1, destinationUnit: 'item', destinationItemId: 'luanuoc', destinationLabel: 'Lúa nước'},
            ],
            orders: [],
          } : emptyTruckerSnapshot.business,
          fleet: {
            bank: 725000,
            ownedVehicles: [],
            rental: emptyTruckerSnapshot.fleet.rental,
            rentalOptions: [
              {key: 'mule', label: 'Mule', model: 'mule', fee: 5000},
              {key: 'benson', label: 'Benson', model: 'benson', fee: 10000},
              {key: 'pounder', label: 'Pounder', model: 'pounder', fee: 15000},
              {key: 'hauler', label: 'Hauler', model: 'hauler', fee: 20000},
              {key: 'packer', label: 'Packer', model: 'packer', fee: 25000},
              {key: 'phantom', label: 'Phantom', model: 'phantom', fee: 30000},
            ],
          },
          orderPage: {
            filter: 'all', page: 1, pageSize: 20, total: 3, items: [
            {
              id: 'dispatch-preview-1', level: 1, categories: ['Nông Nghiệp'],
              availability: 'available', reward: 11200,
              canAccept: true, lockReason: '', rentalRewards: previewRentalRewards(11200),
            },
            {
              id: 'dispatch-preview-2', level: 4, categories: ['Khoáng Sản'],
              availability: 'route_busy', reward: 15200,
              canAccept: false, lockReason: 'Tuyến đang bận', rentalRewards: previewRentalRewards(15200),
            },
            {
              id: 'dispatch-preview-3', level: 1, categories: ['Nông Nghiệp', 'Nuôi Thú'],
              availability: 'available', reward: 3600,
              canAccept: true, lockReason: '', rentalRewards: previewRentalRewards(3600).slice(2),
            },
          ]},
        },
        revision: 1,
      });
    },
  };
}
