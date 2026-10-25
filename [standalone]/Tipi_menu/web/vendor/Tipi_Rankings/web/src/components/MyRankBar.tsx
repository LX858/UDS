import type { LeaderboardData } from '@/types/leaderboard'
import type { BoardTheme } from '@/constants/boardThemes'
import { mpMenuUi } from '@/constants/mpMenuUi'
import { cn, formatNumber } from '@/utils'

interface MyRankBarProps {
	data: LeaderboardData
	onJumpToRank?: () => void
	theme?: BoardTheme
	className?: string
	embedded?: boolean
	updatedAt?: number
}

export default function MyRankBar({
	data,
	onJumpToRank,
	theme,
	className,
	embedded = false,
	updatedAt,
}: MyRankBarProps) {
	const p = data.player
	const topLimit = data.listLimit ?? data.entries.length ?? 20
	const inTopList =
		p?.inTopList === true ||
		(!!p?.myEntryKey && data.entries.some((e) => e.name === p.myEntryKey))
	const outsideTop = !!p?.myEntryKey && !inTopList
	const showRankBlock = inTopList && !!p?.myRank
	const updatedLabel =
		updatedAt != null
			? `Cập nhật ${new Date(updatedAt * 1000).toLocaleString('vi-VN')}`
			: null

	if (!p?.myEntryKey && !showRankBlock && !outsideTop && !updatedLabel) return null

	if (embedded) {
		return (
			<div className={cn(mpMenuUi.footer, 'lb-my-rank-footer', className)}>
				{(showRankBlock || outsideTop) && p && (
					<div className='flex items-center justify-between gap-2'>
						<div className='min-w-0 flex-1'>
							{showRankBlock ? (
								<div className='flex min-w-0 flex-1 flex-wrap items-center gap-x-2 gap-y-0.5'>
									<span className='text-[10px] font-bold uppercase tracking-wider text-white'>
										Hạng của bạn
									</span>
									<span className={mpMenuUi.myRankBadge}>#{p.myRank}</span>
									{p.myValue !== undefined && (
										<span className='flex items-baseline gap-1 tabular-nums'>
											<span className='text-sm font-bold leading-none text-white'>
												{formatNumber(p.myValue)}
											</span>
											<span className='text-[10px] font-semibold uppercase text-white/80'>
												{data.valueLabel}
											</span>
										</span>
									)}
									{p.myLabel && (
										<span className='w-full truncate text-[11px] font-bold uppercase leading-none text-white'>
											{p.myLabel}
										</span>
									)}
								</div>
							) : (
								<p className='text-[11px] font-bold uppercase tracking-wide text-white/85'>
									Ngoài top {topLimit}
								</p>
							)}
						</div>

						{onJumpToRank && inTopList && (
							<button
								type='button'
								onClick={onJumpToRank}
								className={cn(mpMenuUi.myRankBtn, 'shrink-0')}>
								Xem vị trí
							</button>
						)}
					</div>
				)}

				{updatedLabel && (
					<p
						className={cn(
							mpMenuUi.updatedAt,
							(showRankBlock || outsideTop) && 'mt-2 border-t border-[#FFFFFF40] pt-1.5'
						)}>
						{updatedLabel}
					</p>
				)}
			</div>
		)
	}

	if (!p?.myEntryKey && !showRankBlock) return null

	return (
		<div
			className={cn(
				'flex flex-wrap items-center justify-between gap-2 border-t border-white/[0.08] bg-[#090810] px-3 py-2',
				theme?.border,
				className
			)}>
			{showRankBlock ? (
				<div className='min-w-0 text-xs'>
					<span className='text-white/45'>Hạng của bạn: </span>
					<span className={cn('font-heading font-bold', theme?.accent ?? 'text-uls')}>
						#{p.myRank}
					</span>
					{p.myValue !== undefined && (
						<span className='text-white/50'>
							{' '}
							· {formatNumber(p.myValue)} {data.valueLabel}
						</span>
					)}
					{p.myLabel && (
						<span className='block truncate text-[10px] text-white/35'>{p.myLabel}</span>
					)}
				</div>
			) : (
				<span className='text-xs font-semibold uppercase text-white/50'>
					Ngoài top {topLimit}
				</span>
			)}
			{onJumpToRank && inTopList && (
				<button
					type='button'
					onClick={onJumpToRank}
					className='shrink-0 rounded border border-uls/30 bg-uls/10 px-2 py-1 text-[10px] font-semibold uppercase tracking-wide text-uls transition hover:bg-uls/20'>
					Xem vị trí
				</button>
			)}
		</div>
	)
}
