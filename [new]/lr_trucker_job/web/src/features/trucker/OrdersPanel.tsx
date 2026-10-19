import {Boxes, ChevronLeft, ChevronRight, MapPin, RefreshCw} from 'lucide-react';
import type {Localize, TruckerSnapshot} from './model';
import {formatMoney} from './model';

export function OrdersPanel({
  orderPage,
  playerLevel,
  missionActive,
  rentalBlockedReason,
  pending,
  L,
  onRefresh,
  onAccept,
  onList,
}: {
  orderPage: TruckerSnapshot['orderPage'];
  playerLevel: number;
  missionActive: boolean;
  rentalBlockedReason: string;
  pending: string | null;
  L: Localize;
  onRefresh: () => void;
  onAccept: (id: string) => void;
  onList: (filter: 'all', page: number) => void;
}) {
  const orders = orderPage.items;
  const pages = Math.max(1, Math.ceil(orderPage.total / orderPage.pageSize));
  return (
    <section className="trucker-orders min-w-0">
      <div className="mb-4 flex items-center justify-between gap-4">
        <div>
          <h2 className="text-xl font-extrabold tracking-tight text-foreground sm:text-2xl">
            {L('available_orders')}
          </h2>
          <p className="mt-1 text-sm font-medium text-muted-foreground">
            {orderPage.total} tuyến vận chuyển phù hợp
          </p>
        </div>
        <button
          type="button"
          disabled={pending !== null}
          aria-busy={pending === 'refresh'}
          onClick={onRefresh}
          className="trucker-button flex h-10 shrink-0 items-center gap-2 rounded-xl border border-border bg-card px-3.5 text-sm font-bold text-foreground shadow-sm hover:border-amber-400 hover:bg-accent hover:text-accent-foreground focus-visible:outline-none disabled:cursor-not-allowed disabled:opacity-50"
        >
          <RefreshCw
            className={`h-4 w-4 ${pending === 'refresh' ? 'animate-spin' : ''}`}
            strokeWidth={1.8}
          />
          {L('refresh')}
        </button>
      </div>

      {orders.length ? (
        <div className="grid gap-4 2xl:grid-cols-2">
          {orders.map(order => {
            return (
            <article
              key={order.id}
              className="group relative overflow-hidden rounded-2xl border border-border bg-card p-4 shadow-[0_12px_35px_hsl(215_30%_20%/0.07)] transition-[border-color,box-shadow] duration-200 hover:border-amber-400 hover:shadow-[0_16px_40px_rgba(146,64,14,0.10)] sm:p-5"
            >
              <div className="relative">
                <div className="mb-4 flex items-start justify-between gap-3">
                  <div className="min-w-0">
                    <h3 className="text-lg font-extrabold leading-tight text-foreground">
                      Phiếu điều phối
                    </h3>
                    <p className="mt-1.5 flex items-start gap-1.5 text-[13px] font-semibold leading-5 text-muted-foreground">
                      <MapPin className="mt-0.5 h-4 w-4 shrink-0 text-amber-700" strokeWidth={1.8} />
                      <span>Điểm giao và hàng hóa hiện sau khi nhận</span>
                    </p>
                  </div>
                  <div className="flex shrink-0 flex-col items-end gap-2">
                    <span className="text-xs font-extrabold uppercase text-muted-foreground">
                      Cấp {order.level}
                    </span>
                  </div>
                </div>
                <div className="mb-4 grid grid-cols-2 gap-2">
                  <OrderStat label="Hạng mục" value={order.categories.join(' · ')} />
                  <OrderStat label="Công tối đa" value={formatMoney(order.reward)} />
                </div>
                <p className="mb-2 text-[13px] font-semibold leading-5 text-muted-foreground">
                  Xe thuê phù hợp: {order.rentalRewards.map(rental => rental.key).join(', ')}
                </p>
                {!order.canAccept && order.lockReason ? (
                  <p className="mb-3 rounded-lg border border-red-300/50 bg-red-50 px-3 py-2 text-xs font-bold text-red-700 dark:bg-red-950/40 dark:text-red-300">
                    {order.lockReason}
                  </p>
                ) : null}
                {rentalBlockedReason ? (
                  <p className="mb-3 rounded-lg border border-amber-300/50 bg-amber-50 px-3 py-2 text-xs font-bold text-amber-900 dark:bg-amber-950/40 dark:text-amber-200">
                    {rentalBlockedReason}
                  </p>
                ) : null}
                <button
                  type="button"
                  aria-busy={pending === order.id}
                  disabled={
                    missionActive ||
                    rentalBlockedReason !== '' ||
                    pending !== null ||
                    playerLevel < order.level ||
                    order.availability !== 'available' ||
                    !order.canAccept
                  }
                  title={!order.canAccept ? order.lockReason : undefined}
                  onClick={() => onAccept(order.id)}
                  className="trucker-button min-h-11 w-full rounded-xl bg-primary px-4 py-2.5 text-sm font-extrabold text-primary-foreground shadow-sm hover:brightness-95 focus-visible:outline-none disabled:cursor-not-allowed disabled:bg-muted disabled:text-muted-foreground disabled:shadow-none"
                >
                  {rentalBlockedReason || getOrderActionLabel({order, playerLevel, missionActive, pending, L})}
                </button>
              </div>
            </article>
            );
          })}
        </div>
      ) : (
        <div className="grid min-h-72 place-items-center rounded-2xl border border-dashed border-border bg-card/70 px-6 text-center text-muted-foreground">
          <div>
            <div className="mx-auto mb-4 grid h-12 w-12 place-items-center rounded-2xl bg-muted">
              <Boxes className="h-6 w-6" strokeWidth={1.6} />
            </div>
            <p className="text-base font-bold text-foreground">{L('no_orders')}</p>
            <p className="mt-1 text-sm">Hãy làm mới để kiểm tra tuyến vận chuyển mới.</p>
          </div>
        </div>
      )}
      {orderPage.total > orderPage.pageSize ? (
        <nav className="mt-5 flex items-center justify-end gap-2" aria-label="Phân trang đơn hàng">
          <button type="button" aria-label="Trang trước" disabled={pending !== null || orderPage.page <= 1}
            onClick={() => onList(orderPage.filter, orderPage.page - 1)}
            className="trucker-button grid h-10 w-10 place-items-center rounded-xl border border-border bg-card disabled:opacity-40">
            <ChevronLeft className="h-4 w-4" />
          </button>
          <span className="min-w-24 text-center text-sm font-bold text-muted-foreground">
            Trang {orderPage.page}/{pages}
          </span>
          <button type="button" aria-label="Trang sau" disabled={pending !== null || orderPage.page >= pages}
            onClick={() => onList(orderPage.filter, orderPage.page + 1)}
            className="trucker-button grid h-10 w-10 place-items-center rounded-xl border border-border bg-card disabled:opacity-40">
            <ChevronRight className="h-4 w-4" />
          </button>
        </nav>
      ) : null}
    </section>
  );
}

function OrderStat({label, value}: {label: string; value: string}) {
  return (
    <div className="min-w-0 rounded-xl border border-border bg-muted px-2.5 py-2.5">
      <p className="truncate text-xs font-bold uppercase tracking-[0.04em] text-muted-foreground">
        {label}
      </p>
      <p className="mt-0.5 truncate text-sm font-extrabold text-foreground">
        {value}
      </p>
    </div>
  );
}

function getOrderActionLabel({
  order,
  playerLevel,
  missionActive,
  pending,
  L,
}: {
  order: TruckerSnapshot['orderPage']['items'][number];
  playerLevel: number;
  missionActive: boolean;
  pending: string | null;
  L: Localize;
}) {
  if (pending === order.id) return 'Đang xử lý...';
  if (missionActive) return 'Đang thực hiện nhiệm vụ';
  if (playerLevel < order.level) return `Cần đạt cấp ${order.level}`;
  if (order.availability === 'route_busy') return L('route_busy');
  if (order.availability === 'stock_low') return L('stock_low');
  if (order.availability === 'source_unavailable') return 'Nguồn hàng gián đoạn';
  if (!order.canAccept) return 'Không thể nhận đơn';
  if (pending !== null) return 'Vui lòng chờ';
  return L('accept');
}
