import {cleanup, fireEvent, render, screen} from '@testing-library/react';
import {afterEach, describe, expect, it, vi} from 'vitest';
import {OrdersPanel} from '@/features/trucker/OrdersPanel';
import {VehiclePickerModal} from '@/features/trucker/VehiclePickerModal';
import type {TruckerSnapshot} from '@/features/trucker/model';

type Order = TruckerSnapshot['orderPage']['items'][number];

const businessOrder: Order = {
  id: 'dispatch-opaque', level: 1, categories: ['Nông Nghiệp', 'Nuôi Thú'],
  availability: 'available', reward: 9000,
  canAccept: true, lockReason: '',
  rentalRewards: [
    {key: 'hauler', reward: 9000},
    {key: 'packer', reward: 9000},
    {key: 'phantom', reward: 9000},
  ],
};

const fleet: TruckerSnapshot['fleet'] = {
  bank: 100000,
  rental: {
    active: false, status: 'none', key: '', model: '', plate: '',
    startedAt: 0, expiresAt: 0, truckNetId: 0, overageDue: 0, debt: 0,
  },
  ownedVehicles: [{
    vehicleId: 1, model: 'phantom', plate: 'TEST 1', garage: 'pillboxgarage',
    state: 'garaged', tier: 2, capacity: 180, nextUpgradePrice: 350000,
    available: true, unavailableReason: '',
  }],
  rentalOptions: [
    {key: 'mule', label: 'Mule', model: 'mule', fee: 5000},
    {key: 'benson', label: 'Benson', model: 'benson', fee: 10000},
    {key: 'pounder', label: 'Pounder', model: 'pounder', fee: 15000},
    {key: 'hauler', label: 'Hauler', model: 'hauler', fee: 20000},
    {key: 'packer', label: 'Packer', model: 'packer', fee: 25000},
    {key: 'phantom', label: 'Phantom', model: 'phantom', fee: 30000},
  ],
};

afterEach(() => cleanup());

describe('trucker order privacy and vehicle capacity', () => {
  it('keeps business identity and item details hidden in the board and picker', () => {
    render(<OrdersPanel
      orderPage={{filter: 'all', page: 1, pageSize: 20, total: 1, items: [businessOrder]}}
      playerLevel={7} missionActive={false} rentalBlockedReason="" pending={null} L={key => key}
      onRefresh={vi.fn()} onAccept={vi.fn()} onList={vi.fn()}
    />);
    expect(document.body.textContent).toContain('Nông Nghiệp');
    expect(document.body.textContent).toContain('Nuôi Thú');
    expect(document.body.textContent).not.toContain('180 vật phẩm');
    expect(document.body.textContent).not.toContain('15 kiện');
    expect(document.body.innerHTML).not.toContain('Nhà hàng Bí mật');
    expect(document.body.innerHTML).not.toContain('Heo Bí mật');
    cleanup();

    render(<VehiclePickerModal order={businessOrder} fleet={fleet} pending={null}
      error={null} onClose={vi.fn()} onConfirm={vi.fn()} />);
    expect(document.body.textContent).not.toContain('180 vật phẩm');
    expect(document.body.textContent).not.toContain('15 kiện');
    expect(document.body.innerHTML).not.toContain('Nhà hàng Bí mật');
    expect(document.body.innerHTML).not.toContain('Heo Bí mật');
  });

  it('uses item count for capacity and reserves tanker rentals for Packer and Phantom', () => {
    render(<VehiclePickerModal order={businessOrder} fleet={fleet} pending={null}
      error={null} onClose={vi.fn()} onConfirm={vi.fn()} />);
    expect(screen.getAllByRole('radio')).toHaveLength(3);
    expect(screen.queryByText('Mule')).toBeNull();
    expect(screen.queryByText('Benson')).toBeNull();
    expect(screen.queryByText('Pounder')).toBeNull();
    cleanup();

    render(<VehiclePickerModal order={{...businessOrder, categories: ['Khoáng Sản'], rentalRewards: businessOrder.rentalRewards.slice(1)}} fleet={fleet}
      pending={null} error={null} onClose={vi.fn()} onConfirm={vi.fn()} />);
    expect(screen.getAllByRole('radio')).toHaveLength(2);
    expect(screen.queryByText('Hauler')).toBeNull();
    expect(document.body.textContent).toContain('60 phút');
  });

  it('shows exact pay for the chosen rental without exposing load or cargo identity', () => {
    const marketOffer: Order = {
      ...businessOrder, categories: ['Khoáng Sản'], reward: 33000,
      rentalRewards: [
        {key: 'mule', reward: 13000},
        {key: 'phantom', reward: 33000},
      ],
    };
    render(<VehiclePickerModal order={marketOffer} fleet={fleet} pending={null}
      error={null} onClose={vi.fn()} onConfirm={vi.fn()} />);
    expect(screen.getByText('Công tối đa theo xe đã chọn').nextElementSibling?.textContent).toBe('$13.000');
    expect(screen.getByRole('radio', {name: /Mule/i}).textContent).not.toContain('50 vật phẩm');
    fireEvent.click(screen.getByRole('radio', {name: /Phantom/i}));
    expect(screen.getByText('Công tối đa theo xe đã chọn').nextElementSibling?.textContent).toBe('$33.000');
    expect(document.body.innerHTML).not.toContain('Nhà hàng Bí mật');
  });
});
