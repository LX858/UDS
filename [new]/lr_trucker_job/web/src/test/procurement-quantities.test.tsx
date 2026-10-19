import {cleanup, fireEvent, render, screen} from '@testing-library/react';
import {afterEach, describe, expect, it, vi} from 'vitest';
import {ProcurementPortal} from '@/features/trucker/ProcurementPortal';
import type {TruckerSnapshot} from '@/features/trucker/model';
import type {TruckerController} from '@/features/trucker/useTruckerController';

afterEach(() => cleanup());

describe('business order quantities', () => {
  it('uses fixed quantity buttons without a freeform number input', () => {
    const snapshot = {
      business: {
        label: 'Quán nước', businessId: 'bar', sourceOnline: true,
        balance: 1000000, feeRate: 10, orders: [],
        catalog: [{
          itemId: 'coconut', label: 'Dừa', category: 'traicay',
          destinationItemId: 'dua_soche', destinationLabel: 'Dừa sơ chế',
          destinationUnit: 'item', destinationMultiplier: 1,
          unitsPerPackage: 12, unitPrice: 100, available: 0,
        }],
      },
    } as unknown as TruckerSnapshot;
    const controller = {
      pending: null, error: null, close: vi.fn(),
      createBusinessOrder: vi.fn(), cancelBusinessOrder: vi.fn(),
    } as unknown as TruckerController;

    render(<ProcurementPortal snapshot={snapshot} controller={controller}
      theme="light" onThemeChange={vi.fn()} />);

    expect(screen.queryByRole('spinbutton')).toBeNull();
    const quantityGroup = screen.getByRole('group', {name: 'Số lượng Dừa'});
    expect(quantityGroup.querySelectorAll('button')).toHaveLength(4);
    for (const quantity of [50, 100, 150, 200]) {
      expect(screen.getByRole('button', {name: `${quantity} Dừa`})).toBeTruthy();
    }
    const fifty = screen.getByRole('button', {name: '50 Dừa'});
    fireEvent.click(fifty);
    expect(fifty.getAttribute('aria-pressed')).toBe('true');
    expect(document.body.textContent).toContain('50/250');
    fireEvent.click(fifty);
    expect(fifty.getAttribute('aria-pressed')).toBe('false');
    expect(document.body.textContent).toContain('0/250');
  });
});
