import * as Dialog from '@radix-ui/react-dialog';
import {
  Box, Building2, Minus, Moon, PackageCheck, Plus, ShoppingCart,
  Sun, Truck, WalletCards, X,
} from 'lucide-react';
import {useMemo, useState} from 'react';
import type {TruckerSnapshot} from './model';
import {formatConversion, formatMoney} from './model';
import type {TruckerController} from './useTruckerController';
import type {TruckerTheme} from './useTruckerTheme';

export function ProcurementPortal({
  snapshot,
  controller,
  theme,
  onThemeChange,
}: {
  snapshot: TruckerSnapshot;
  controller: TruckerController;
  theme: TruckerTheme;
  onThemeChange: (theme: TruckerTheme) => void;
}) {
  const context = snapshot.business;
  const [cart, setCart] = useState<Record<string, number>>({});
  const [confirmOpen, setConfirmOpen] = useState(false);
  const summary = useMemo(() => {
    let goods = 0;
    let packages = 0;
    let units = 0;
    const lines: Array<{itemId: string; quantity: number}> = [];
    for (const item of context.catalog) {
      const quantity = Math.max(0, Math.floor(cart[item.itemId] ?? 0));
      if (!quantity) continue;
      lines.push({itemId: item.itemId, quantity});
      goods += quantity * item.unitPrice;
      units += quantity;
      packages += Math.ceil(quantity / item.unitsPerPackage);
    }
    const delivery = Math.floor(goods * context.feeRate / 100);
    return {goods, packages, units, delivery, total: goods + delivery, lines};
  }, [cart, context]);
  const busy = controller.pending !== null;
  const valid = summary.lines.length > 0
    && summary.lines.length <= 6
    && summary.units <= 250
    && summary.packages <= 21
    && summary.total <= context.balance
    && context.sourceOnline;

  const adjust = (itemId: string, delta: number) => {
    setCart(current => ({
      ...current,
      [itemId]: Math.max(0, Math.min(10000, (current[itemId] ?? 0) + delta)),
    }));
  };

  return (
    <main className="trucker-viewport bg-[radial-gradient(circle_at_18%_8%,rgba(217,119,6,0.17),transparent_30%),rgba(15,23,42,0.68)]">
      <section data-ui="trucker-dialog" role="dialog" aria-modal="true" aria-label="Đặt giao nguyên liệu"
        className="logistics-grid trucker-shell relative flex flex-col overflow-hidden border border-border/80 bg-background text-foreground shadow-[0_32px_90px_rgba(2,6,23,0.42)]">
        <header className="flex min-h-[84px] items-center justify-between gap-4 border-b border-border bg-card/90 px-4 py-4 sm:px-6">
          <div className="flex min-w-0 items-center gap-3.5">
            <span className="grid h-12 w-12 shrink-0 place-items-center rounded-2xl border border-amber-300/60 bg-accent text-amber-700 dark:text-amber-300">
              <Building2 className="h-6 w-6" />
            </span>
            <div className="min-w-0">
              <p className="text-xs font-extrabold uppercase tracking-[.14em] text-amber-700 dark:text-amber-300">Cổng cung ứng B2B</p>
              <h1 className="truncate text-xl font-extrabold sm:text-2xl">{context.label}</h1>
              <p className="text-sm font-medium text-muted-foreground">Đặt nguyên liệu và theo dõi giao hàng</p>
            </div>
          </div>
          <div className="flex items-center gap-2">
            <div className="hidden rounded-xl border border-border bg-muted px-3 py-2 sm:block">
              <p className="text-xs font-bold uppercase text-muted-foreground">Quỹ doanh nghiệp</p>
              <p className="text-sm font-extrabold">{formatMoney(context.balance)}</p>
            </div>
            <button type="button" aria-label={theme === 'light' ? 'Dùng giao diện tối' : 'Dùng giao diện sáng'}
              onClick={() => onThemeChange(theme === 'light' ? 'dark' : 'light')}
              className="trucker-button grid h-11 w-11 place-items-center rounded-xl border border-border bg-card focus-visible:outline-none">
              {theme === 'light' ? <Moon className="h-4 w-4" /> : <Sun className="h-4 w-4" />}
            </button>
            <button type="button" aria-label="Đóng" onClick={() => void controller.close()}
              className="trucker-button grid h-11 w-11 place-items-center rounded-xl border border-border bg-card focus-visible:outline-none">
              <X className="h-5 w-5" />
            </button>
          </div>
        </header>

        {!context.sourceOnline ? (
          <div role="alert" className="mx-4 mt-4 rounded-xl border border-red-300/60 bg-red-50 px-4 py-3 text-sm font-bold text-red-700 dark:bg-red-950/40 dark:text-red-300 sm:mx-6">
            Nguồn xn-sellitem đang gián đoạn. Bạn có thể xem đơn nhưng chưa thể tạo đơn mới.
          </div>
        ) : null}
        {controller.error ? (
          <div role="alert" className="mx-4 mt-4 rounded-xl border border-red-300/60 bg-red-50 px-4 py-3 text-sm font-bold text-red-700 dark:bg-red-950/40 dark:text-red-300 sm:mx-6">
            {controller.error}
          </div>
        ) : null}

        <div className="grid min-h-0 flex-1 gap-5 overflow-y-auto p-4 sm:p-6 lg:grid-cols-[minmax(0,1fr)_360px]">
          <section aria-labelledby="catalog-title" className="min-w-0">
            <div className="mb-4">
              <h2 id="catalog-title" className="text-xl font-extrabold">Danh mục nguyên liệu</h2>
              <p className="mt-1 text-sm font-medium text-muted-foreground">Giá được khóa tại thời điểm xác nhận. Có thể đặt khi kho nguồn bằng 0.</p>
            </div>
            <div className="grid gap-3 md:grid-cols-2">
              {context.catalog.map(item => {
                const quantity = cart[item.itemId] ?? 0;
                return (
                  <article key={item.itemId} className="rounded-2xl border border-border bg-card p-4 shadow-sm">
                    <div className="flex items-start justify-between gap-3">
                      <div>
                        <h3 className="text-base font-extrabold">{item.destinationLabel}</h3>
                        <p className="mt-1 text-sm font-semibold text-muted-foreground">{formatMoney(item.unitPrice)} / đơn vị nguồn</p>
                        <p className="mt-1 text-sm text-muted-foreground">{formatConversion({...item, quantity: quantity || 1, destinationAmount: (quantity || 1) * item.destinationMultiplier})}</p>
                      </div>
                      <span className={`rounded-lg px-2.5 py-1 text-xs font-extrabold ${item.available > 0
                        ? 'bg-emerald-50 text-emerald-700 dark:bg-emerald-950/50 dark:text-emerald-300'
                        : 'bg-red-50 text-red-700 dark:bg-red-950/50 dark:text-red-300'}`}>
                        Kho: {item.available}
                      </span>
                    </div>
                    <div className="mt-4 flex items-center justify-between gap-3 rounded-xl bg-muted p-2">
                      <button type="button" aria-label={`Giảm ${item.label}`} disabled={busy || quantity <= 0}
                        onClick={() => adjust(item.itemId, -1)} className="trucker-button grid h-10 w-10 place-items-center rounded-lg bg-card disabled:opacity-40">
                        <Minus className="h-4 w-4" />
                      </button>
                      <label className="min-w-0 flex-1 text-center">
                        <span className="sr-only">Số lượng {item.label}</span>
                        <input type="number" min={0} max={10000} value={quantity} disabled={busy}
                          onChange={event => setCart(current => ({...current, [item.itemId]: Math.max(0, Math.min(10000, Math.floor(Number(event.target.value) || 0)))}))}
                          className="h-10 w-full rounded-lg border border-border bg-background px-2 text-center text-base font-extrabold outline-none focus-visible:ring-2 focus-visible:ring-ring" />
                      </label>
                      <button type="button" aria-label={`Tăng ${item.label}`} disabled={busy}
                        onClick={() => adjust(item.itemId, 1)} className="trucker-button grid h-10 w-10 place-items-center rounded-lg bg-card disabled:opacity-40">
                        <Plus className="h-4 w-4" />
                      </button>
                    </div>
                  </article>
                );
              })}
            </div>

            <div className="mt-6">
              <h2 className="text-lg font-extrabold">Đơn đang hoạt động</h2>
              <div className="mt-3 space-y-3">
                {context.orders.length ? context.orders.map(order => (
                  <article key={order.id} className="flex flex-col gap-3 rounded-2xl border border-border bg-card p-4 sm:flex-row sm:items-center sm:justify-between">
                    <div>
                      <p className="font-extrabold">{order.lines.map(formatConversion).join(' · ')}</p>
                      <p className="mt-1 text-sm font-semibold text-muted-foreground">
                        {order.businessStatus === 'in_transit' ? 'Đang vận chuyển' : order.availability === 'available' ? 'Sẵn sàng cho tài xế' : order.lockReason}
                      </p>
                    </div>
                    <button type="button" disabled={busy || !['waiting_stock', 'available'].includes(order.businessStatus)}
                      onClick={() => void controller.cancelBusinessOrder(order.id)}
                      className="trucker-button min-h-10 rounded-xl border border-red-300 px-4 text-sm font-extrabold text-red-700 disabled:opacity-40 dark:text-red-300">
                      Hủy và hoàn tiền
                    </button>
                  </article>
                )) : (
                  <div className="rounded-2xl border border-dashed border-border p-8 text-center text-sm font-semibold text-muted-foreground">Chưa có đơn đang hoạt động.</div>
                )}
              </div>
            </div>
          </section>

          <aside className="h-fit rounded-2xl border border-border bg-card p-5 shadow-sm lg:sticky lg:top-0">
            <div className="flex items-center gap-2">
              <ShoppingCart className="h-5 w-5 text-amber-700 dark:text-amber-300" />
              <h2 className="text-lg font-extrabold">Tóm tắt đơn hàng</h2>
            </div>
            <div className="mt-4 grid grid-cols-2 gap-2">
              <Summary icon={Box} label="Mặt hàng" value={String(summary.lines.length)} />
              <Summary icon={Truck} label="Vật phẩm" value={`${summary.units}/250`} />
              <Summary icon={PackageCheck} label="Kiện quy đổi" value={`${summary.packages}/21`} />
              <Summary icon={WalletCards} label="Số dư" value={formatMoney(context.balance)} />
            </div>
            <div className="mt-5 space-y-2 border-t border-border pt-4 text-sm">
              {summary.lines.map(line => {
                const item = context.catalog.find(entry => entry.itemId === line.itemId)!;
                return <div key={line.itemId} className="text-sm font-semibold">{formatConversion({...item, quantity: line.quantity, destinationAmount: line.quantity * item.destinationMultiplier})}</div>;
              })}
            </div>
            <dl className="mt-4 space-y-2 text-sm">
              <div className="flex justify-between gap-4"><dt className="text-muted-foreground">Tiền hàng</dt><dd className="font-bold">{formatMoney(summary.goods)}</dd></div>
              <div className="flex justify-between gap-4"><dt className="text-muted-foreground">Phí giao hàng</dt><dd className="font-bold">{formatMoney(summary.delivery)}</dd></div>
              <div className="flex justify-between gap-4 pt-2 text-base"><dt className="font-extrabold">Tổng thanh toán</dt><dd className="font-extrabold text-amber-700 dark:text-amber-300">{formatMoney(summary.total)}</dd></div>
            </dl>
            {summary.packages > 21 ? <p className="mt-3 text-sm font-bold text-red-700 dark:text-red-300">Giỏ hàng vượt quá 21 kiện.</p> : null}
            {summary.units > 250 ? <p className="mt-3 text-sm font-bold text-red-700 dark:text-red-300">Giỏ hàng vượt quá 250 vật phẩm.</p> : null}
            {summary.total > context.balance ? <p className="mt-3 text-sm font-bold text-red-700 dark:text-red-300">Quỹ doanh nghiệp không đủ.</p> : null}
            <button type="button" disabled={!valid || busy} aria-busy={controller.pending === 'create-business-order'}
              onClick={() => setConfirmOpen(true)}
              className="trucker-button mt-5 min-h-11 w-full rounded-xl bg-primary px-4 text-sm font-extrabold text-primary-foreground disabled:bg-muted disabled:text-muted-foreground">
              {controller.pending === 'create-business-order' ? 'Đang tạo đơn...' : 'Đặt giao hàng'}
            </button>
          </aside>
        </div>
      </section>

      <Dialog.Root open={confirmOpen} onOpenChange={open => { if (!busy) setConfirmOpen(open); }}>
        <Dialog.Portal>
          <Dialog.Overlay className="fixed inset-0 z-50 bg-slate-950/70" />
          <Dialog.Content data-ui="business-confirmation" className="fixed left-1/2 top-1/2 z-50 max-h-[calc(100dvh-2rem)] w-[min(28rem,calc(100%-2rem))] -translate-x-1/2 -translate-y-1/2 overflow-y-auto rounded-2xl border border-border bg-popover p-5 text-popover-foreground shadow-2xl focus:outline-none">
            <Dialog.Title className="text-xl font-extrabold">Xác nhận thanh toán</Dialog.Title>
            <Dialog.Description className="mt-2 text-sm font-medium text-muted-foreground">
              Trừ {formatMoney(summary.total)} từ quỹ {context.label}. Tiền sẽ được giữ cho đến khi giao xong hoặc doanh nghiệp hủy trước khi có tài xế.
            </Dialog.Description>
            <div className="mt-3 space-y-2 text-sm font-semibold">
              {summary.lines.map(line => {
                const item = context.catalog.find(entry => entry.itemId === line.itemId)!;
                return <p key={line.itemId}>{formatConversion({...item, quantity: line.quantity, destinationAmount: line.quantity * item.destinationMultiplier})}</p>;
              })}
            </div>
            {controller.error ? <p role="alert" className="mt-3 text-sm font-semibold text-destructive">{controller.error}</p> : null}
            <div className="mt-5 flex justify-end gap-2">
              <Dialog.Close disabled={busy} className="trucker-button min-h-10 rounded-xl border border-border px-4 text-sm font-bold">Quay lại</Dialog.Close>
              <button type="button" disabled={busy || !valid} aria-busy={busy} onClick={() => void controller.createBusinessOrder(context.businessId, summary.lines).then(success => {
                if (success) { setCart({}); setConfirmOpen(false); }
              })} className="trucker-button min-h-10 rounded-xl bg-primary px-4 text-sm font-extrabold text-primary-foreground disabled:opacity-50">
                Xác nhận đặt hàng
              </button>
            </div>
          </Dialog.Content>
        </Dialog.Portal>
      </Dialog.Root>
    </main>
  );
}

function Summary({icon: Icon, label, value}: {icon: typeof Box; label: string; value: string}) {
  return (
    <div className="rounded-xl bg-muted p-3">
      <Icon className="h-4 w-4 text-amber-700 dark:text-amber-300" />
      <p className="mt-2 text-xs font-bold uppercase text-muted-foreground">{label}</p>
      <p className="mt-0.5 truncate text-sm font-extrabold">{value}</p>
    </div>
  );
}
