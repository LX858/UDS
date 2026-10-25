import type { LeaderboardEntry } from '@/types/leaderboard'
import { cn } from '@/utils'
import PodiumCardBg from '@/components/PodiumCardBg'
import PodiumScoreWell from '@/components/PodiumScoreWell'
import LeaderboardAvatar from '@/components/LeaderboardAvatar'
import CountUpNumber from '@/components/CountUpNumber'

const stripOrder = [2, 1, 3] as const

const topRankLabel: Record<1 | 2 | 3, string> = {
	1: 'TOP 1',
	2: 'TOP 2',
	3: 'TOP 3',
}

const podiumTheme: Record<
	1 | 2 | 3,
	{
		height: number
		contentTop: string
		ring: string
		badge: string
	}
> = {
	1: {
		height: 228,
		contentTop: '13%',
		ring: 'ring-2 ring-yellow-400/80',
		badge: 'border-yellow-400/90 bg-black/75 text-yellow-200 shadow-[0_0_8px_rgba(250,204,21,0.35)]',
	},
	2: {
		height: 204,
		contentTop: '11%',
		ring: 'ring-2 ring-slate-300/70',
		badge: 'border-slate-300/80 bg-black/75 text-slate-100 shadow-[0_0_6px_rgba(148,163,184,0.25)]',
	},
	3: {
		height: 204,
		contentTop: '11%',
		ring: 'ring-2 ring-orange-400/65',
		badge: 'border-orange-400/80 bg-black/75 text-orange-200 shadow-[0_0_6px_rgba(251,146,60,0.3)]',
	},
}

function TopRankBadge({ rank }: { rank: 1 | 2 | 3 }) {
	const theme = podiumTheme[rank]
	return (
		<div className='lb-podium-top-badge flex w-full shrink-0 justify-center pb-2 pt-0.5'>
			<span
				className={cn(
					'rounded border px-2.5 py-1 text-[10px] font-black uppercase tracking-[0.12em]',
					theme.badge
				)}>
				{topRankLabel[rank]}
			</span>
		</div>
	)
}

function PodiumCard({
	entry,
	valueLabel,
	fallbackLogoUrl,
	animate,
	embedded,
}: {
	entry: LeaderboardEntry
	valueLabel: string
	fallbackLogoUrl?: string
	animate: boolean
	embedded?: boolean
}) {
	const rank = entry.rank as 1 | 2 | 3
	const theme = podiumTheme[rank]
	const scoreBottom = embedded ? '28%' : '26%'

	return (
		<div
			className='lb-podium-slot relative flex min-w-0 flex-col animate-slide-up'
			style={{
				height: theme.height,
				animationDelay: `${rank * 80}ms`,
			}}>
			<div className='lb-podium-card relative min-h-0 flex-1 overflow-hidden'>
				<PodiumCardBg
					rank={rank}
					embedded={embedded}
					className='absolute inset-0 h-full w-full'
				/>

				<div
					className='absolute inset-x-[8%] z-10 flex min-h-0 flex-col items-center'
					style={{ top: theme.contentTop, bottom: scoreBottom }}>
					<TopRankBadge rank={rank} />

					<div className='flex min-h-0 w-full flex-1 flex-col items-center justify-center gap-2 px-0.5'>
						<LeaderboardAvatar
							label={entry.label}
							logoUrl={entry.logoUrl}
							fallbackLogoUrl={fallbackLogoUrl}
							className='h-12 w-12 shrink-0'
							ringClass={theme.ring}
							textClass='text-[10px]'
							centered
							embedded={embedded}
						/>

						<p
							className={cn(
								'line-clamp-2 w-full text-center font-heading font-extrabold leading-snug text-white',
								embedded ? 'lb-podium-name text-[12px]' : 'text-[11px]'
							)}
							title={entry.label}>
							{entry.label}
						</p>
					</div>
				</div>

				<PodiumScoreWell
					rank={rank}
					valueLabel={valueLabel}
					value={<CountUpNumber value={entry.value} active={animate} />}
					embedded={embedded}
				/>
			</div>
		</div>
	)
}

interface TopThreeStripProps {
	entries: LeaderboardEntry[]
	valueLabel: string
	fallbackLogoUrl?: string
	animate?: boolean
	embedded?: boolean
}

export default function TopThreeStrip({
	entries,
	valueLabel,
	fallbackLogoUrl,
	animate = true,
	embedded = false,
}: TopThreeStripProps) {
	const top3 = stripOrder
		.map((rank) => entries.find((e) => e.rank === rank))
		.filter(Boolean) as LeaderboardEntry[]

	if (top3.length === 0) return null

	return (
		<div className='lb-podium-stage mx-auto flex w-full max-w-[440px] justify-center px-1 pb-1 pt-0.5'>
			<div className='lb-podium w-full min-w-0'>
				<div className='lb-podium-grid grid grid-cols-[1fr_1.08fr_1fr] items-end gap-2'>
					{top3.map((entry) => (
						<PodiumCard
							key={`top-${entry.rank}-${entry.name}`}
							entry={entry}
							valueLabel={valueLabel}
							fallbackLogoUrl={fallbackLogoUrl}
							animate={animate}
							embedded={embedded}
						/>
					))}
				</div>
				<div
					className={cn(
						'lb-podium-shelf mx-[6%] mt-1.5 h-px rounded-full bg-gradient-to-r from-transparent to-transparent',
						embedded ? 'via-[#00e5ff]/50' : 'via-uls/30'
					)}
				/>
			</div>
		</div>
	)
}
