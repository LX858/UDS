import {describe, expect, it} from 'vitest';
import {formatConversion} from '@/features/trucker/model';
import {createDefaultBrowserMock} from '@/app/browser.mock';

describe('processed business ingredients', () => {
  it('keeps source and received amounts separate', () => {
    expect(formatConversion({quantity: 10, label: 'Lúa mì', destinationAmount: 20, destinationLabel: 'Gạo', destinationUnit: 'item'}))
      .toBe('10 Lúa mì → 20 Gạo');
    expect(formatConversion({quantity: 10, label: 'Dầu thô', destinationAmount: 200, destinationLabel: 'Nhiên liệu', destinationUnit: 'liter'}))
      .toBe('10 Dầu thô → 200 lít Nhiên liệu');
  });

  it('provides mock RPC responses for procurement and existing gameplay', async () => {
    const rpc = createDefaultBrowserMock().rpc!.trucker!;
    const responses = await Promise.all([
      rpc.close!({}), rpc.refresh!({}), rpc.cancelMission!({}),
      rpc.acceptOrder!({offerId: 'test', vehicle: {mode: 'rental', key: 'mule'}}),
      rpc.upgradeVehicle!({vehicleId: 1}),
      rpc.getBusinessContext!({businessId: 'bar'}),
      rpc.listOrderBoard!({filter: 'all', page: 1, pageSize: 20}),
      rpc.createBusinessOrder!({businessId: 'bar', lines: [{itemId: 'coconut', quantity: 1}]}),
      rpc.cancelBusinessOrder!({orderId: 'test'}),
    ]);
    for (const response of responses) {
      expect(response).toMatchObject({success: true});
    }
  });

  it('boots the business catalog with explicit processed outputs', async () => {
    const previousUrl = window.location.href;
    window.history.replaceState({}, '', '/?procurement=1');
    try {
      const envelopes: unknown[] = [];
      await createDefaultBrowserMock().boot!(envelope => { envelopes.push(envelope); return true; });
      expect(envelopes).toEqual(expect.arrayContaining([
        expect.objectContaining({name: 'snapshot', payload: expect.objectContaining({
          business: expect.objectContaining({active: true, catalog: expect.arrayContaining([
            expect.objectContaining({itemId: 'luami', destinationItemId: 'gao', destinationMultiplier: 1}),
            expect.objectContaining({itemId: 'coconut', destinationItemId: 'dua_soche'}),
          ])}),
        })}),
      ]));
    } finally {
      window.history.replaceState({}, '', previousUrl);
    }
  });
});
