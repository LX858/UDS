import {CircleDollarSign, Gauge, MapPin, Truck} from 'lucide-react';
import type {TruckerSnapshot} from './model';
import {formatMoney} from './model';

export function GaragePanel({
  fleet,
  missionActive,
  pending,
  onUpgrade,
}: {
  fleet: TruckerSnapshot['fleet'];
  missionActive: boolean;
  pending: string | null;
  onUpgrade: (vehicleId: number) => void;
}) {
  return (
    <section className="trucker-orders min-w-0" aria-labelledby="garage-title">
      <div className="mb-5">
        <h2 id="garage-title" className="text-xl font-extrabold tracking-tight text-foreground sm:text-2xl">
          Garage đầu kéo
        </h2>
        <p className="mt-1 text-sm font-medium text-muted-foreground">
          Phantom và Phantom2 đã mua từ đại lý xe
        </p>
      </div>

      {fleet.ownedVehicles.length ? (
        <div className="grid gap-4 lg:grid-cols-2">
          {fleet.ownedVehicles.map(vehicle => {
            const maxTier = vehicle.nextUpgradePrice === 0;
            const actionPending = pending === `upgrade-${vehicle.vehicleId}`;
            const disabled =
              missionActive || pending !== null || !vehicle.available || maxTier;
            return (
              <article
                key={vehicle.vehicleId}
                className="rounded-2xl border border-border bg-card p-5 shadow-[0_12px_35px_hsl(215_30%_20%/0.07)]"
              >
                <div className="flex items-start justify-between gap-4">
                  <div className="flex min-w-0 items-center gap-3">
                    <div className="grid h-11 w-11 shrink-0 place-items-center rounded-xl bg-accent text-amber-700 dark:text-amber-300">
                      <Truck className="h-5 w-5" strokeWidth={1.8} />
                    </div>
                    <div className="min-w-0">
                      <h3 className="truncate text-lg font-extrabold uppercase text-foreground">
                        {vehicle.model}
                      </h3>
                      <p className="mt-0.5 text-sm font-bold text-muted-foreground">
                        Biển số {vehicle.plate}
                      </p>
                    </div>
                  </div>
                  <Status state={vehicle.state} />
                </div>

                <div className="mt-5 grid grid-cols-2 gap-3 sm:grid-cols-3">
                  <GarageStat icon={Gauge} label="Cấp nghề" value={`Cấp ${vehicle.tier}`} />
                  <GarageStat icon={Truck} label="Tải trọng" value={`${vehicle.capacity} vật phẩm`} />
                  <GarageStat
                    icon={MapPin}
                    label="Garage"
                    value={vehicle.garage || 'Chưa xác định'}
                    wide
                  />
                </div>

                {!vehicle.available ? (
                  <p className="mt-4 rounded-xl border border-amber-300/50 bg-accent px-3 py-2 text-sm font-semibold text-accent-foreground">
                    {vehicle.unavailableReason}
                  </p>
                ) : null}

                <button
                  type="button"
                  disabled={disabled}
                  aria-busy={actionPending}
                  onClick={() => onUpgrade(vehicle.vehicleId)}
                  className="trucker-button mt-4 flex min-h-11 w-full items-center justify-center gap-2 rounded-xl bg-primary px-4 text-sm font-extrabold text-primary-foreground shadow-sm hover:brightness-95 focus-visible:outline-none disabled:cursor-not-allowed disabled:bg-muted disabled:text-muted-foreground disabled:shadow-none"
                >
                  <CircleDollarSign className="h-4 w-4" strokeWidth={1.8} />
                  {actionPending
                    ? 'Đang nâng cấp...'
                    : maxTier
                      ? 'Đã đạt cấp tối đa'
                      : `Nâng cấp ${formatMoney(vehicle.nextUpgradePrice)}`}
                </button>
              </article>
            );
          })}
        </div>
      ) : (
        <div className="grid min-h-72 place-items-center rounded-2xl border border-dashed border-border bg-card/70 px-6 text-center">
          <div>
            <div className="mx-auto mb-4 grid h-12 w-12 place-items-center rounded-2xl bg-muted text-muted-foreground">
              <Truck className="h-6 w-6" strokeWidth={1.6} />
            </div>
            <p className="text-base font-bold text-foreground">Chưa có đầu kéo phù hợp</p>
            <p className="mt-1 text-sm text-muted-foreground">
              Mua Phantom hoặc Phantom2 tại doanh nghiệp cardealer để xe xuất hiện tại đây.
            </p>
          </div>
        </div>
      )}
    </section>
  );
}

function GarageStat({
  icon: Icon,
  label,
  value,
  wide = false,
}: {
  icon: typeof Gauge;
  label: string;
  value: string;
  wide?: boolean;
}) {
  return (
    <div className={`min-w-0 rounded-xl bg-muted p-3 ${wide ? 'col-span-2 sm:col-span-1' : ''}`}>
      <p className="flex items-center gap-1.5 text-xs font-bold uppercase text-muted-foreground">
        <Icon className="h-3.5 w-3.5" strokeWidth={1.8} /> {label}
      </p>
      <p className="mt-1 truncate text-sm font-extrabold text-foreground">{value}</p>
    </div>
  );
}

function Status({state}: {state: TruckerSnapshot['fleet']['ownedVehicles'][number]['state']}) {
  const label = state === 'garaged' ? 'Trong garage' : state === 'impounded' ? 'Tạm giữ' : 'Đang ở ngoài';
  const className = state === 'garaged'
    ? 'border-emerald-300/60 bg-emerald-50 text-emerald-700 dark:bg-emerald-950/50 dark:text-emerald-300'
    : state === 'impounded'
      ? 'border-red-300/60 bg-red-50 text-red-700 dark:bg-red-950/50 dark:text-red-300'
      : 'border-cyan-300/60 bg-cyan-50 text-cyan-700 dark:bg-cyan-950/50 dark:text-cyan-300';
  return <span className={`shrink-0 rounded-lg border px-2.5 py-1 text-xs font-extrabold ${className}`}>{label}</span>;
}
