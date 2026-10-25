import { forwardRef } from 'react'
import type { LeaderboardEntry } from '@/types/leaderboard'
import type { BoardTheme } from '@/constants/boardThemes'
import { mpMenuUi } from '@/constants/mpMenuUi'
import { cn, formatNumber } from '@/utils'
import { getEntryBadges } from '@/utils/entryBadges'
import CountUpNumber from '@/components/CountUpNumber'

export const LB_TABLE_GRID_COMPACT =
	'grid grid-cols-[32px_minmax(0,1fr)_56px_80px] items-center gap-2.5 px-3'

export const LB_TABLE_GRID_EMBEDDED =
	'grid grid-cols-[40px_minmax(0,1fr)_minmax(64px,72px)_92px] items-center gap-x-3'

interface EntryRowProps {
	entry: LeaderboardEntry
	entryType?: 'gang' | 'player'
	isSelf?: boolean
	animateValues?: boolean
	theme?: BoardTheme
	zebra?: boolean
	embedded?: boolean
}

function embeddedBadgeClass(key: string): string {
	switch (key) {
		case 'top10':
			return mpMenuUi.badgeTop10
		case 'up':
			return mpMenuUi.badgeUp
		case 'down':
			return mpMenuUi.badgeDown
		default:
			return mpMenuUi.badgeSteady
	}
}

const EntryRow = forwardRef<HTMLDivElement, EntryRowProps>(function EntryRow(
	{ entry, entryType = 'gang', isSelf, animateValues, theme, zebra, embedded = false },
	ref
) {
	const isTopTen = entry.rank <= 10
	const badges = getEntryBadges(entry)
	const levelText = entry.level > 0 ? String(entry.level) : '—'

	return (
		<div
			ref={ref}
			data-rank={entry.rank}
			data-self={isSelf ? '1' : undefined}
			className={cn(
				embedded ? LB_TABLE_GRID_EMBEDDED : LB_TABLE_GRID_COMPACT,
				'group relative cursor-default transition-all duration-200',
				embedded
					? cn(mpMenuUi.row, isSelf && mpMenuUi.rowSelf)
					: cn(
							'rounded-md border px-3 hover:border-uls/35 hover:bg-uls/[0.07]',
							zebra && entry.rank % 2 === 0 && 'bg-white/[0.02]',
							'border-white/[0.06] bg-black/20',
							isTopTen && 'border-uls/10',
							isSelf && 'border-uls/40 bg-uls/10 ring-1 ring-uls/25'
						)
			)}>
			<div
				className={cn(
					embedded
						? isSelf
							? mpMenuUi.rankBadgeSelf
							: isTopTen
								? mpMenuUi.rankBadgeTop
								: mpMenuUi.rankBadge
						: cn(
								'flex h-7 w-7 shrink-0 items-center justify-center rounded font-heading text-xs font-bold',
								isSelf
									? 'bg-uls text-black'
									: isTopTen
										? 'bg-uls/10 text-uls'
										: 'text-white/45'
							)
				)}>
				{entry.rank}
			</div>

			<div className='flex min-w-0 items-center gap-1.5'>
				<p
					className={cn(
						'min-w-0 flex-1 truncate',
						embedded
							? isSelf
								? mpMenuUi.nameSelf
								: mpMenuUi.name
							: 'font-heading text-[13px] font-semibold leading-tight',
						!embedded && (isSelf ? 'text-uls' : 'text-white/90')
					)}
					title={entry.label}>
					{entry.label}
					{isSelf && (
						<span className={embedded ? mpMenuUi.nameYou : 'ml-1 text-[10px] font-normal text-uls/80'}>
							{' '}
							(Bạn)
						</span>
					)}
				</p>

				{badges.length > 0 && (
					<div className='flex shrink-0 items-center gap-1'>
						{badges.map((b) => (
							<span
								key={b.key}
								className={cn(
									embedded ? cn(mpMenuUi.badge, embeddedBadgeClass(b.key)) : cn(
										'rounded border px-1 py-px text-[8px] font-semibold uppercase',
										b.className
									)
								)}>
								{b.label}
							</span>
						))}
					</div>
				)}
			</div>

			<p
				className={cn(
					embedded ? mpMenuUi.levelCol : 'text-center text-xs font-semibold tabular-nums text-white/75',
					embedded && 'text-[13px]'
				)}
				title={entryType === 'player' ? `Cấp nghề ${levelText}` : `Cấp ${levelText}`}>
				{levelText}
			</p>

			<p
				className={cn(
					embedded
						? isSelf
							? mpMenuUi.valueSelf
							: mpMenuUi.value
						: cn('text-right font-heading text-sm font-bold tabular-nums', theme?.accent ?? 'text-uls')
				)}>
				{animateValues ? (
					<CountUpNumber value={entry.value} active={animateValues} />
				) : (
					formatNumber(entry.value)
				)}
			</p>
		</div>
	)
})

export default EntryRow
