import {useEffect, useState} from 'react';
import {useAppRuntime} from '@/app/runtimeContext';
import {playUiSound} from './sound';

export function useTruckerController() {
  const runtime = useAppRuntime();
  const [pending, setPending] = useState<string | null>(null);
  const [error, setError] = useState<string | null>(null);

  useEffect(() => {
    void runtime.start().catch(startError => {
      setError(
        startError instanceof Error
          ? startError.message
          : 'Runtime startup failed'
      );
    });
    const keyHandler = (event: KeyboardEvent) => {
      if (event.key !== 'Escape') return;
      if (document.querySelector('[data-ui="vehicle-picker"], [data-ui="business-confirmation"]')) return;
      void closeRuntime(runtime, setError);
    };
    let hovered: Element | null = null;
    const pointerHandler = (event: PointerEvent) => {
      const target = event.target instanceof Element
        ? event.target.closest('button:not(:disabled), [data-ui-sound="hover"]')
        : null;
      if (target && target !== hovered) {
        hovered = target;
        playUiSound('hover');
      }
    };
    const pointerOutHandler = (event: PointerEvent) => {
      if (hovered && event.relatedTarget instanceof Node && hovered.contains(event.relatedTarget)) return;
      hovered = null;
    };
    const clickHandler = (event: MouseEvent) => {
      if (event.target instanceof Element && event.target.closest('button:not(:disabled)')) {
        playUiSound('press');
      }
    };
    window.addEventListener('keydown', keyHandler, true);
    window.addEventListener('pointerover', pointerHandler);
    window.addEventListener('pointerout', pointerOutHandler);
    window.addEventListener('click', clickHandler);
    return () => {
      window.removeEventListener('keydown', keyHandler, true);
      window.removeEventListener('pointerover', pointerHandler);
      window.removeEventListener('pointerout', pointerOutHandler);
      window.removeEventListener('click', clickHandler);
    };
  }, [runtime]);

  const runAction = async (
    key: string,
    action: () => Promise<{success: boolean; message: string}>
  ) => {
    if (pending) return false;
    setPending(key);
    setError(null);
    try {
      const result = await action();
      if (result.success) playUiSound('success');
      else {
        setError(result.message);
        playUiSound('error');
      }
      return result.success;
    } catch (actionError) {
      setError(
        actionError instanceof Error ? actionError.message : 'Action failed'
      );
      playUiSound('error');
      return false;
    } finally {
      setPending(null);
    }
  };

  return {
    pending,
    error,
    close: () => closeRuntime(runtime, setError),
    refresh: () =>
      runAction('refresh', () =>
        runtime.nui.nui.trucker.rpc.refresh.call({})
      ),
    listOrders: (filter: 'all', page: number) =>
      runAction('orders-page', () =>
        runtime.nui.nui.trucker.rpc.listOrderBoard.call({filter, page, pageSize: 20})
      ),
    createBusinessOrder: (
      businessId: string,
      lines: Array<{itemId: string; quantity: number}>
    ) => runAction('create-business-order', () =>
      runtime.nui.nui.trucker.rpc.createBusinessOrder.call({businessId, lines})
    ),
    cancelBusinessOrder: (orderId: string) =>
      runAction(`cancel-business-${orderId}`, () =>
        runtime.nui.nui.trucker.rpc.cancelBusinessOrder.call({orderId})
      ),
    acceptOrder: (
      id: string,
      vehicle: {mode: 'rental'; key: 'mule' | 'benson' | 'pounder' | 'hauler' | 'packer' | 'phantom'}
    ) =>
      runAction(id, () =>
        runtime.nui.nui.trucker.rpc.acceptOrder.call({offerId: id, vehicle})
      ),
    cancelMission: () =>
      runAction('cancel', () =>
        runtime.nui.nui.trucker.rpc.cancelMission.call({})
      ),
    returnRental: () =>
      runAction('return-rental', () =>
        runtime.nui.nui.trucker.rpc.returnRental.call({})
      ),
    settleRentalDebt: () =>
      runAction('settle-rental-debt', () =>
        runtime.nui.nui.trucker.rpc.settleRentalDebt.call({})
      ),
    upgradeVehicle: (vehicleId: number) =>
      runAction(`upgrade-${vehicleId}`, () =>
        runtime.nui.nui.trucker.rpc.upgradeVehicle.call({vehicleId})
      ),
  };
}

export type TruckerController = ReturnType<typeof useTruckerController>;

async function closeRuntime(
  runtime: ReturnType<typeof useAppRuntime>,
  setError: (error: string | null) => void
) {
  setError(null);
  playUiSound('close');
  try {
    await runtime.close();
  } catch (closeError) {
    setError(
      closeError instanceof Error ? closeError.message : 'Failed to close'
    );
  }
}
