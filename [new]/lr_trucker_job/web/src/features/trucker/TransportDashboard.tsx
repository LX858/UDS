import {useEffect, useState} from 'react';
import type {Localize, TruckerSnapshot, VehicleSelection} from './model';
import type {TruckerController} from './useTruckerController';
import type {TruckerTheme} from './useTruckerTheme';
import {ActiveMissionCard} from './MissionWidgets';
import {OrdersPanel} from './OrdersPanel';
import {ProcurementPortal} from './ProcurementPortal';
import {TransportHeader} from './TransportHeader';
import {VehiclePickerModal} from './VehiclePickerModal';
import {formatMoney} from './model';

export function TransportDashboard({
  snapshot,
  L,
  closeLabel,
  controller,
  theme,
  onThemeChange,
}: {
  snapshot: TruckerSnapshot;
  L: Localize;
  closeLabel: string;
  controller: TruckerController;
  theme: TruckerTheme;
  onThemeChange: (theme: TruckerTheme) => void;
}) {
  const [selectedOrderId, setSelectedOrderId] = useState<string | null>(null);
  const selectedOrder = snapshot.orderPage.items.find(order => order.id === selectedOrderId);
  const rental = snapshot.fleet.rental;
  const rentalBlockedReason = rental.debt > 0
    ? `Cần thanh toán phụ phí còn nợ ${formatMoney(rental.debt)} trước khi nhận đơn mới.`
    : rental.status === 'pending' || rental.status === 'returning'
      ? 'Lượt thuê đang chờ quyết toán. Vui lòng thử lại sau.'
      : '';

  useEffect(() => {
    if (selectedOrderId && !selectedOrder) setSelectedOrderId(null);
  }, [selectedOrder, selectedOrderId]);

  const confirmOrder = (selection: VehicleSelection) => {
    if (!selectedOrder) return Promise.resolve(false);
    return controller.acceptOrder(selectedOrder.id, selection);
  };

  if (snapshot.business.active) {
    return (
      <ProcurementPortal
        snapshot={snapshot}
        controller={controller}
        theme={theme}
        onThemeChange={onThemeChange}
      />
    );
  }

  return (
    <main className="trucker-viewport bg-[radial-gradient(circle_at_18%_8%,rgba(217,119,6,0.17),transparent_30%),rgba(15,23,42,0.68)]">
      <section
        data-ui="trucker-dialog"
        role="dialog"
        aria-modal="true"
        aria-label="Trung tâm vận chuyển"
        className="logistics-grid trucker-shell relative flex flex-col overflow-hidden border border-border/80 bg-background text-foreground shadow-[0_32px_90px_rgba(2,6,23,0.42)]"
      >
        <TransportHeader
          player={snapshot.player}
          L={L}
          closeLabel={closeLabel}
          theme={theme}
          onThemeChange={onThemeChange}
          onClose={() => void controller.close()}
        />

        {controller.error && !selectedOrder ? (
          <div role="alert" className="mx-4 mt-4 rounded-xl border border-red-300/60 bg-red-50 px-4 py-3 text-sm font-semibold text-red-700 dark:bg-red-950/50 dark:text-red-300 sm:mx-6">
            {controller.error}
          </div>
        ) : null}

        {rental.status !== 'none' || rental.debt > 0 ? (
          <div className="mx-4 mt-4 flex flex-wrap items-center gap-3 rounded-2xl border border-amber-400/40 bg-card px-4 py-3 text-sm sm:mx-6">
            <div className="min-w-0 flex-1">
              {rental.active ? (
                <p className="font-bold text-foreground">
                  Xe đang thuê: {snapshot.fleet.rental.model.toUpperCase()} · {snapshot.fleet.rental.plate}
                  {' · '}Hết 60 phút lúc {new Date(snapshot.fleet.rental.expiresAt * 1000).toLocaleTimeString('vi-VN')}
                </p>
              ) : null}
              <p className="text-muted-foreground">
                {rental.active
                  ? `Hoàn thành đơn vẫn giữ xe. Trả tại bãi bằng phím E; phụ phí hiện tại ${formatMoney(snapshot.fleet.rental.overageDue)}.`
                  : rental.status === 'pending'
                    ? 'Phí thuê đang chờ thanh toán hoặc xác nhận. Chưa thể nhận đơn mới.'
                    : rental.status === 'returning'
                      ? 'Lượt thuê đang chờ đóng và quyết toán.'
                      : 'Xe đã trả.'}
                {snapshot.fleet.rental.debt > 0
                  ? ` Phụ phí còn nợ ${formatMoney(snapshot.fleet.rental.debt)}; cần thanh toán trước khi nhận đơn mới.`
                  : ''}
              </p>
            </div>
            {rental.debt > 0 || rental.status === 'pending' ? (
              <button type="button" disabled={controller.pending !== null}
                onClick={() => void controller.settleRentalDebt()}
                className="trucker-button rounded-xl bg-primary px-4 py-2 font-bold text-primary-foreground disabled:opacity-50">
                {rental.status === 'pending' ? 'Hoàn tất thuê xe' : 'Thanh toán phụ phí'}
              </button>
            ) : null}
            {rental.active || rental.status === 'returning' ? (
              <button type="button" disabled={snapshot.mission.active || controller.pending !== null}
                onClick={() => void controller.returnRental()}
                className="trucker-button rounded-xl border border-border bg-muted px-4 py-2 font-bold text-foreground disabled:opacity-50">
                {rental.status === 'returning' ? 'Hoàn tất trả xe' : 'Trả xe tại bãi'}
              </button>
            ) : null}
          </div>
        ) : null}

        <div className={`trucker-body min-h-0 flex-1 ${snapshot.mission.active ? '' : 'trucker-body--solo'}`}>
          <OrdersPanel
            orderPage={snapshot.orderPage}
            playerLevel={snapshot.player.level}
            missionActive={snapshot.mission.active}
            rentalBlockedReason={rentalBlockedReason}
            pending={controller.pending}
            L={L}
            onRefresh={() => void controller.refresh()}
            onAccept={setSelectedOrderId}
            onList={(filter, page) => void controller.listOrders(filter, page)}
          />
          {snapshot.mission.active ? (
            <aside className="trucker-sidebar space-y-4">
              <ActiveMissionCard
                mission={snapshot.mission}
                pending={controller.pending}
                L={L}
                onCancel={() => void controller.cancelMission()}
              />
            </aside>
          ) : null}
        </div>
      </section>

      {selectedOrder ? (
        <VehiclePickerModal
          order={selectedOrder}
          fleet={snapshot.fleet}
          pending={controller.pending}
          error={controller.error}
          onClose={() => setSelectedOrderId(null)}
          onConfirm={confirmOrder}
        />
      ) : null}
    </main>
  );
}
