import * as Dialog from '@radix-ui/react-dialog';
import {Check, Clock3, Truck, X} from 'lucide-react';
import {useEffect, useMemo, useState} from 'react';
import type {TruckerSnapshot, VehicleSelection} from './model';
import {formatMoney} from './model';

type Order = TruckerSnapshot['orderPage']['items'][number];

type PickerOption = {
  id: string;
  title: string;
  detail: string;
  term: string;
  fee: number;
  reward: number;
  disabled: boolean;
  disabledReason: string;
  selection: VehicleSelection;
};

export function VehiclePickerModal({
  order,
  fleet,
  pending,
  error,
  onClose,
  onConfirm,
}: {
  order: Order;
  fleet: TruckerSnapshot['fleet'];
  pending: string | null;
  error: string | null;
  onClose: () => void;
  onConfirm: (selection: VehicleSelection) => Promise<boolean>;
}) {
  const options = useMemo(() => buildOptions(order, fleet), [order, fleet]);
  const [selectedId, setSelectedId] = useState('');
  const busy = pending === order.id;

  useEffect(() => {
    const preferred = options.find(option => !option.disabled);
    setSelectedId(preferred?.id ?? '');
  }, [options]);

  const selected = options.find(option => option.id === selectedId && !option.disabled);

  return (
    <Dialog.Root open onOpenChange={open => !open && !busy && onClose()}>
      <Dialog.Portal>
        <Dialog.Overlay className="fixed inset-0 z-50 bg-slate-950/70 backdrop-blur-[2px]" />
        <Dialog.Content
          data-ui="vehicle-picker"
          className="fixed left-1/2 top-1/2 z-50 flex max-h-[calc(100dvh-2rem)] w-[min(46rem,calc(100%-2rem))] -translate-x-1/2 -translate-y-1/2 flex-col overflow-hidden rounded-3xl border border-border bg-popover text-popover-foreground shadow-[0_28px_90px_rgba(2,6,23,0.46)] focus:outline-none"
        >
          <div className="flex items-start justify-between gap-4 border-b border-border px-5 py-5 sm:px-6">
            <div>
              <Dialog.Title className="text-xl font-extrabold tracking-tight sm:text-2xl">
                Chọn xe thuê
              </Dialog.Title>
              <Dialog.Description className="mt-1 text-sm font-medium text-muted-foreground">
                {`Hạng mục: ${order.categories.join(' · ')}. Hàng hóa và điểm giao hiện sau khi nhận.`}
              </Dialog.Description>
            </div>
            <Dialog.Close asChild>
              <button
                type="button"
                aria-label="Đóng chọn phương tiện"
                disabled={busy}
                className="trucker-button grid h-10 w-10 shrink-0 place-items-center rounded-xl border border-border bg-card text-muted-foreground hover:bg-muted hover:text-foreground focus-visible:outline-none disabled:opacity-50"
              >
                <X className="h-5 w-5" strokeWidth={1.8} />
              </button>
            </Dialog.Close>
          </div>

          <div className="min-h-0 flex-1 overflow-y-auto px-5 py-5 sm:px-6">
            {options.length ? (
              <div role="radiogroup" aria-label="Phương tiện phù hợp" className="grid gap-3 sm:grid-cols-2">
                {options.map(option => {
                  const active = option.id === selectedId;
                  return (
                    <button
                      key={option.id}
                      type="button"
                      role="radio"
                      aria-checked={active}
                      disabled={option.disabled || busy}
                      onClick={() => setSelectedId(option.id)}
                      className={`trucker-button relative min-h-36 rounded-2xl border p-4 text-left focus-visible:outline-none disabled:cursor-not-allowed disabled:opacity-60 ${
                        active
                          ? 'border-amber-400 bg-accent shadow-[0_0_0_1px_hsl(var(--primary)/0.18)]'
                          : 'border-border bg-card hover:border-amber-400/70 hover:bg-muted/70'
                      }`}
                    >
                      <div className="flex items-start gap-3">
                        <div className="grid h-10 w-10 shrink-0 place-items-center rounded-xl bg-muted text-amber-700 dark:text-amber-300">
                          <Truck className="h-5 w-5" strokeWidth={1.8} />
                        </div>
                        <div className="min-w-0 flex-1">
                          <p className="truncate text-base font-extrabold uppercase text-foreground">{option.title}</p>
                          <p className="mt-0.5 text-xs font-semibold text-muted-foreground">{option.detail}</p>
                        </div>
                        {active ? (
                          <span className="grid h-6 w-6 place-items-center rounded-full bg-primary text-primary-foreground">
                            <Check className="h-3.5 w-3.5" strokeWidth={2.2} />
                          </span>
                        ) : null}
                      </div>
                      <div className="mt-4 grid grid-cols-2 gap-2 text-xs">
                        <OptionStat icon={Clock3} label="Thời hạn" value={option.term} />
                        <OptionStat label="Phí thuê" value={option.fee ? formatMoney(option.fee) : 'Không có'} />
                      </div>
                      {option.disabledReason ? (
                        <p className="mt-3 text-xs font-bold text-red-700 dark:text-red-300">{option.disabledReason}</p>
                      ) : null}
                    </button>
                  );
                })}
              </div>
            ) : (
              <div className="rounded-2xl border border-dashed border-border bg-muted/60 px-5 py-10 text-center">
                <Truck className="mx-auto h-8 w-8 text-muted-foreground" strokeWidth={1.6} />
                <p className="mt-3 text-base font-extrabold text-foreground">Không có phương tiện phù hợp</p>
                <p className="mt-1 text-sm text-muted-foreground">
                  {fleet.rental.status === 'pending' || fleet.rental.status === 'returning'
                    ? 'Lượt thuê đang chờ quyết toán. Hãy xử lý xong trước khi nhận đơn.'
                    : fleet.rental.active
                      ? 'Xe đang thuê không phù hợp với phiếu này. Hãy trả xe tại bãi trước khi chọn xe khác.'
                      : 'Hãy chọn phiếu có tải trọng phù hợp với xe thuê.'}
                </p>
              </div>
            )}

            {error ? (
              <p role="alert" className="mt-4 rounded-xl border border-red-300/60 bg-red-50 px-4 py-3 text-sm font-semibold text-red-700 dark:bg-red-950/50 dark:text-red-300">
                {error}
              </p>
            ) : null}
          </div>

          <div className="border-t border-border bg-muted/45 px-5 py-4 sm:px-6">
            <div className="flex flex-col gap-3 sm:flex-row sm:items-center sm:justify-between">
              <div>
                <p className="text-xs font-bold uppercase text-muted-foreground">
                  Công tối đa theo xe đã chọn
                </p>
                <p className="text-lg font-extrabold text-foreground">
                  {formatMoney(selected?.reward ?? order.reward)}
                </p>
                {fleet.rental.active ? (
                  <p className="mt-1 text-xs font-medium text-muted-foreground">
                    Dùng xe đang thuê; không thu thêm phí thuê. Phụ phí sau 60 phút tiếp tục tính đến khi trả xe.
                  </p>
                ) : selected?.fee ? (
                  <p className="mt-1 text-xs font-medium text-muted-foreground">
                    Phí thuê {formatMoney(selected.fee)} cho 60 phút; quá giờ thêm 3% phí thuê mỗi phút.
                  </p>
                ) : null}
              </div>
              <button
                type="button"
                disabled={!selected || busy}
                aria-busy={busy}
                onClick={() => {
                  if (!selected) return;
                  void onConfirm(selected.selection).then(success => success && onClose());
                }}
                className="trucker-button min-h-11 rounded-xl bg-primary px-6 text-sm font-extrabold text-primary-foreground shadow-sm hover:brightness-95 focus-visible:outline-none disabled:cursor-not-allowed disabled:bg-muted disabled:text-muted-foreground"
              >
                {busy ? 'Đang nhận đơn...' : fleet.rental.active ? 'Dùng xe đang thuê và nhận đơn' : 'Thuê xe và nhận đơn'}
              </button>
            </div>
          </div>
        </Dialog.Content>
      </Dialog.Portal>
    </Dialog.Root>
  );
}

function buildOptions(order: Order, fleet: TruckerSnapshot['fleet']): PickerOption[] {
  if (fleet.rental.debt > 0 || fleet.rental.status === 'pending' || fleet.rental.status === 'returning') {
    return [];
  }
  const rentals = fleet.rentalOptions
    .filter(option =>
      order.rentalRewards.some(load => load.key === option.key)
      && (!fleet.rental.active || fleet.rental.key === option.key)
    )
    .sort((first, second) => first.fee - second.fee)
    .map(option => ({
      id: `rental:${option.key}`,
      title: option.label,
      detail: fleet.rental.active ? 'Xe đang thuê · dùng tiếp' : 'Thuê 60 phút · quá giờ 3%/phút',
      term: fleet.rental.active ? 'Đang thuê' : '60 phút',
      fee: fleet.rental.active ? 0 : option.fee,
      reward: order.rentalRewards.find(load => load.key === option.key)!.reward,
      disabled: !fleet.rental.active && fleet.bank < option.fee,
      disabledReason: !fleet.rental.active && fleet.bank < option.fee ? 'Số dư ngân hàng không đủ' : '',
      selection: {mode: 'rental', key: option.key} as const,
    }));
  return rentals;
}

function OptionStat({
  icon: Icon,
  label,
  value,
}: {
  icon?: typeof Clock3;
  label: string;
  value: string;
}) {
  return (
    <div className="min-w-0 rounded-lg bg-muted px-2.5 py-2">
      <p className="flex items-center gap-1 font-bold uppercase text-muted-foreground">
        {Icon ? <Icon className="h-3 w-3" strokeWidth={1.8} /> : null}
        {label}
      </p>
      <p className="mt-1 truncate font-extrabold text-foreground">{value}</p>
    </div>
  );
}
