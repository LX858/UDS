import {PackageCheck, Truck} from 'lucide-react';
import type {Localize, TruckerSnapshot} from './model';
import {formatConversion, missionSteps} from './model';

export function ActiveMissionCard({
  mission,
  pending,
  L,
  onCancel,
}: {
  mission: TruckerSnapshot['mission'];
  pending: string | null;
  L: Localize;
  onCancel: () => void;
}) {
  if (!mission.active) return null;
  const stepKey = missionSteps[mission.step - 1];
  return (
    <section className="rounded-2xl border border-emerald-300/60 bg-emerald-50/70 p-4 shadow-[0_10px_30px_rgba(6,78,59,0.06)] dark:bg-emerald-950/40">
      <div className="flex items-start gap-3">
        <div className="grid h-9 w-9 shrink-0 place-items-center rounded-xl bg-card text-emerald-700 shadow-sm dark:text-emerald-300">
          <PackageCheck className="h-4.5 w-4.5" strokeWidth={1.8} />
        </div>
        <div className="min-w-0 flex-1">
          <p className="text-xs font-bold uppercase tracking-[0.08em] text-emerald-700">Nhiệm vụ đang chạy</p>
          <h3 className="mt-1 truncate text-base font-extrabold text-foreground">
            {mission.orderKind === 'business' ? mission.name : mission.itemLabel}
          </h3>
          {mission.orderKind === 'business' ? (
            <p className="mt-1 text-sm font-semibold text-muted-foreground">{mission.itemLabel}</p>
          ) : null}
          {mission.lines.length > 0 ? <p className="mt-2 text-sm text-muted-foreground">{mission.lines.map(formatConversion).join(' · ')}</p> : null}
          <p className="mt-1 text-xs font-bold text-muted-foreground">
            {mission.logisticsUnits} vật phẩm · {mission.packageAmount} kiện · {mission.destination}
          </p>
          <p className="mt-2 text-[13px] font-medium leading-5 text-muted-foreground">
            {stepKey ? L(stepKey) : ''}
          </p>
        </div>
      </div>
      {mission.status === 'active' ? (
        <button
          type="button"
          disabled={pending !== null}
          aria-busy={pending === 'cancel'}
          onClick={onCancel}
          className="trucker-button mt-4 min-h-10 w-full rounded-xl border border-red-300/60 bg-card px-3 text-sm font-bold text-red-700 hover:bg-red-50 focus-visible:outline-none disabled:cursor-not-allowed disabled:opacity-45 dark:text-red-300 dark:hover:bg-red-950/50"
        >
          {L('cancel')}
        </button>
      ) : null}
    </section>
  );
}

export function MissionHud({
  mission,
  L,
}: {
  mission: TruckerSnapshot['mission'];
  L: Localize;
}) {
  const packageProgress = mission.step >= 6 ? mission.delivered : mission.loaded;
  const percentage =
    mission.packageAmount > 0
      ? Math.round((packageProgress / mission.packageAmount) * 100)
      : 0;
  const stepLabel = mission.cargoMode === 'tanker' && mission.step === 6
    ? `Đang bơm ${mission.fuelLiters.toLocaleString('vi-VN')} lít vào trạm`
    : L(missionSteps[mission.step - 1] ?? 'mission_progress');
  return (
    <aside className="fixed right-2 top-2 z-40 w-[calc(100%-1rem)] max-w-[23rem] overflow-hidden rounded-2xl border border-border bg-card/95 text-foreground shadow-[0_18px_55px_rgba(15,23,42,0.34)] sm:right-5 sm:top-5">
      <div className="h-1.5 bg-muted">
        <div
          className="h-full bg-primary transition-all duration-500"
          style={{
            width: `${mission.status === 'completed' ? 100 : (mission.step / 7) * 100}%`,
          }}
        />
      </div>
      <div className="p-4">
        <div className="flex items-start gap-3">
          <div className="grid h-11 w-11 shrink-0 place-items-center rounded-xl bg-accent text-amber-700 dark:text-amber-300">
            <Truck className="h-5 w-5" strokeWidth={1.8} />
          </div>
          <div className="min-w-0 flex-1">
            <p className="text-xs font-bold uppercase tracking-[0.08em] text-amber-700">
              {L('mission_progress')} - {mission.step}/7
            </p>
            <h2 className="mt-1 truncate text-base font-extrabold text-foreground">
              {mission.orderKind === 'business' ? mission.name : mission.itemLabel}
            </h2>
            <p className="mt-1 truncate text-xs font-semibold text-muted-foreground">
              {mission.logisticsUnits} vật phẩm · {mission.destination}
            </p>
            <p className="mt-1 text-sm font-medium leading-5 text-muted-foreground">
              {mission.status === 'completed'
                ? 'Hoàn thành nhiệm vụ'
                : stepLabel}
            </p>
          </div>
        </div>
        {mission.step === 3 || mission.step === 6 ? (
          <div className="mt-4">
            <div className="mb-2 flex justify-between text-xs font-bold text-muted-foreground">
              <span>{mission.cargoMode === 'tanker' ? 'Tiến trình bơm' : L('packages')}</span>
              <span>
                {mission.cargoMode === 'tanker'
                  ? `${mission.fuelProgress}%`
                  : `${packageProgress}/${mission.packageAmount}`}
              </span>
            </div>
            <div className="h-2 overflow-hidden rounded-full bg-muted">
              <div
                className="h-full rounded-full bg-emerald-600 transition-all"
                style={{width: `${mission.cargoMode === 'tanker' ? mission.fuelProgress : percentage}%`}}
              />
            </div>
          </div>
        ) : null}
      </div>
    </aside>
  );
}
