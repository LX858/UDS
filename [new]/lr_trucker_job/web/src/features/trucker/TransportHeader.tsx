import {
  Banknote,
  Landmark,
  Moon,
  Route,
  Sun,
  Truck,
  X,
  type LucideIcon,
} from 'lucide-react';
import type {Localize, TruckerSnapshot} from './model';
import {formatMoney} from './model';
import type {TruckerTheme} from './useTruckerTheme';

export function TransportHeader({
  player,
  L,
  closeLabel,
  theme,
  onThemeChange,
  onClose,
}: {
  player: TruckerSnapshot['player'];
  L: Localize;
  closeLabel: string;
  theme: TruckerTheme;
  onThemeChange: (theme: TruckerTheme) => void;
  onClose: () => void;
}) {
  return (
    <header className="relative flex min-h-[84px] items-center justify-between gap-4 border-b border-border bg-card/90 px-4 py-4 sm:px-6">
      <div className="flex min-w-0 items-center gap-3.5">
        <div className="grid h-12 w-12 shrink-0 place-items-center rounded-2xl border border-amber-300/60 bg-accent text-amber-700 shadow-sm dark:text-amber-300">
          <Truck className="h-6 w-6" strokeWidth={1.8} />
        </div>
        <div className="min-w-0">
          <p className="mb-0.5 text-xs font-bold uppercase tracking-[0.16em] text-amber-700 dark:text-amber-300">
            Trung tâm điều phối
          </p>
          <h1 className="truncate text-xl font-extrabold tracking-tight text-foreground sm:text-2xl">
            {L('transport')}
          </h1>
          <p className="mt-0.5 truncate text-[13px] font-medium text-muted-foreground">
            {player.name || 'Người vận chuyển'} - ID {player.source || '-'}
          </p>
        </div>
      </div>

      <div className="flex shrink-0 items-center gap-2">
        <Metric icon={Banknote} label={L('cash')} value={formatMoney(player.cash)} />
        <Metric icon={Landmark} label="Ngân hàng" value={formatMoney(player.bank)} />
        <Metric icon={Route} label={L('level')} value={String(player.level)} />
        <div
          className="flex h-11 items-center rounded-xl border border-border bg-muted p-1"
          role="group"
          aria-label="Chọn giao diện"
        >
          <ThemeButton
            active={theme === 'light'}
            label="Giao diện sáng"
            icon={Sun}
            onClick={() => onThemeChange('light')}
          />
          <ThemeButton
            active={theme === 'dark'}
            label="Giao diện tối"
            icon={Moon}
            onClick={() => onThemeChange('dark')}
          />
        </div>
        <button
          data-ui="trucker-close"
          type="button"
          aria-label={closeLabel}
          onClick={onClose}
          className="trucker-button ml-0.5 grid h-11 w-11 place-items-center rounded-xl border border-border bg-card text-muted-foreground shadow-sm hover:border-amber-400 hover:bg-accent hover:text-accent-foreground focus-visible:outline-none"
        >
          <X className="h-5 w-5" strokeWidth={1.8} />
        </button>
      </div>
    </header>
  );
}

function Metric({icon: Icon, label, value}: {icon: LucideIcon; label: string; value: string}) {
  return (
    <div className="hidden min-w-[92px] items-center gap-2.5 rounded-xl border border-border bg-muted px-3 py-2 md:flex">
      <Icon className="h-4 w-4 text-amber-700 dark:text-amber-300" strokeWidth={1.8} />
      <div>
        <p className="text-xs font-bold uppercase tracking-[0.06em] text-muted-foreground">{label}</p>
        <p className="text-sm font-extrabold leading-tight text-foreground">{value}</p>
      </div>
    </div>
  );
}

function ThemeButton({
  active,
  label,
  icon: Icon,
  onClick,
}: {
  active: boolean;
  label: string;
  icon: LucideIcon;
  onClick: () => void;
}) {
  return (
    <button
      type="button"
      aria-label={label}
      aria-pressed={active}
      onClick={onClick}
      className={`trucker-button grid h-8 w-8 place-items-center rounded-lg focus-visible:outline-none ${
        active
          ? 'bg-card text-amber-700 shadow-sm dark:text-amber-300'
          : 'text-muted-foreground hover:text-foreground'
      }`}
    >
      <Icon className="h-4 w-4" strokeWidth={1.8} />
    </button>
  );
}
