import RewardCard from './RewardCard'
import type { CalendarMonth } from '../utils/calendar'
import type { Locales, RewardConfig, RewardStatus } from '../types'

interface CalendarGridProps {
	month: CalendarMonth
	statuses: Record<number, RewardStatus>
	todayReward: number
	locales: Locales
	title?: string
	track?: 'normal' | 'vip'
	locked?: boolean
	lockHint?: string
	missedClaimPrice?: number
	checkedCount?: number
	monthFreeDays?: Record<string, boolean>
	missedClaimsCount?: number
	maxMissedClaimsPerMonth?: number
	onClaimStreak: (day: number, reward: RewardConfig) => void
	onDenyFeedback?: (message: string) => void
}

export default function CalendarGrid({
	month,
	statuses,
	todayReward,
	locales,
	title,
	track = 'normal',
	locked = false,
	lockHint,
	missedClaimPrice = 0,
	checkedCount,
	monthFreeDays = {},
	missedClaimsCount = 0,
	maxMissedClaimsPerMonth = 0,
	onClaimStreak,
	onDenyFeedback,
}: CalendarGridProps) {
	const checked =
		checkedCount ??
		Object.values(statuses).filter((status) => status === 'collected').length
	const rowCount = Math.ceil(month.daysInMonth / 10)

	const showMissedLimit = track === 'normal' && maxMissedClaimsPerMonth > 0
	return (
		<section className={`cal-shell${track === 'vip' ? ' cal-shell-vip' : ''}${locked ? ' cal-shell-locked' : ''}`}>
			<div className='cal-month-title flex items-center justify-between'>
				<div className='flex items-center gap-3'>
					<h2 className='tipi-label text-sm font-bold tracking-[0.12em] text-[var(--cyan)]'>
						{title ?? month.label}
					</h2>
					{showMissedLimit && (
						<span className='tipi-label border border-[rgba(0,229,255,0.15)] bg-[rgba(0,229,255,0.04)] px-2 py-0.5 text-[9px] uppercase tracking-wider text-[var(--text-sub)]'>
							LƯỢT BÙ: {missedClaimsCount}/{maxMissedClaimsPerMonth}
						</span>
					)}
				</div>
				<span className='tipi-label text-[10px] text-[var(--text-muted)]'>
					{checked}/{month.daysInMonth}
				</span>
			</div>

			{locked ? (
				<div className='cal-vip-lock-banner'>
					<span>{lockHint ?? locales.VipLocked ?? 'Mua gói VIP tháng này để mở điểm danh VIP'}</span>
				</div>
			) : null}

			<div className='cal-grid' style={{ ['--cal-rows' as string]: rowCount }}>
				{month.cells.map((cell) => {
					if (!cell.reward) return null

					return (
						<RewardCard
							key={`${track}-${cell.year}-${cell.month}-${cell.dayOfMonth}`}
							dayOfMonth={cell.dayOfMonth}
							todayReward={todayReward}
							reward={cell.reward}
							status={statuses[cell.dayOfMonth] ?? 'undiscovered'}
							locales={locales}
							isToday={cell.dayOfMonth === todayReward}
							vipTrack={track === 'vip'}
							isFreeClaim={!!monthFreeDays[String(cell.dayOfMonth)]}
							missedClaimPrice={missedClaimPrice}
							missedClaimsCount={missedClaimsCount}
							maxMissedClaimsPerMonth={maxMissedClaimsPerMonth}
							onClaimStreak={onClaimStreak}
							onDenyFeedback={onDenyFeedback}
						/>
					)
				})}
			</div>
		</section>
	)
}
