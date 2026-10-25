import type { LeaderboardEntry } from '@/types/leaderboard'
import { cn, formatNumber } from '@/utils'
import LeaderboardAvatar from '@/components/LeaderboardAvatar'

const podiumOrder = [2, 1, 3]

const rankTheme: Record<
	number,
	{
		ring: string
		pedestal: string
		pedestalHeight: string
		avatarSize: string
		glow: string
		accent: string
		number: string
	}
> = {
	1: {
		ring: 'ring-2 ring-yellow-400/70 shadow-[0_0_22px_rgba(250,204,21,0.35)]',
		pedestal: 'from-amber-300 via-yellow-500 to-amber-800',
		pedestalHeight: 'h-[72px]',
		avatarSize: 'h-[68px] w-[68px]',
		glow: 'bg-yellow-400/12',
		accent: 'text-yellow-300',
		number: 'text-yellow-950/90',
	},
	2: {
		ring: 'ring-2 ring-slate-300/60 shadow-[0_0_16px_rgba(203,213,225,0.2)]',
		pedestal: 'from-slate-200 via-slate-400 to-slate-600',
		pedestalHeight: 'h-[52px]',
		avatarSize: 'h-[56px] w-[56px]',
		glow: 'bg-slate-300/8',
		accent: 'text-slate-200',
		number: 'text-slate-900/85',
	},
	3: {
		ring: 'ring-2 ring-orange-400/55 shadow-[0_0_14px_rgba(251,146,60,0.18)]',
		pedestal: 'from-orange-300 via-amber-600 to-orange-900',
		pedestalHeight: 'h-[40px]',
		avatarSize: 'h-[56px] w-[56px]',
		glow: 'bg-orange-400/8',
		accent: 'text-orange-200',
		number: 'text-orange-950/85',
	},
}

interface PodiumProps {
	entries: LeaderboardEntry[]
	valueLabel: string
	entryType?: 'gang' | 'player'
}

function PodiumCard({
	entry,
	valueLabel,
	isCenter,
	entryType = 'gang',
}: {
	entry: LeaderboardEntry
	valueLabel: string
	isCenter?: boolean
	entryType?: 'gang' | 'player'
}) {
	const theme = rankTheme[entry.rank] ?? rankTheme[3]

	return (
		<div
			className={cn(
				'group relative flex flex-1 flex-col items-center animate-slide-up',
				isCenter ? 'z-10 -mt-1' : 'mt-5'
			)}
			style={{ animationDelay: `${entry.rank * 80}ms` }}>
			<div
				className={cn(
					'pointer-events-none absolute inset-x-2 top-6 bottom-0 rounded-2xl opacity-80',
					theme.glow
				)}
			/>

			<div className='relative z-10 mb-3 flex w-full max-w-[148px] flex-col items-center'>
				<LeaderboardAvatar
					label={entry.label}
					logoUrl={entry.logoUrl}
					className={theme.avatarSize}
					ringClass={theme.ring}
					textClass='text-sm'
				/>

				<div className='mt-3 w-full rounded-xl border border-white/8 bg-white/[0.04] px-3 py-2.5 text-center'>
					<p
						className={cn(
							'truncate font-heading font-bold leading-tight text-white',
							isCenter ? 'text-[15px]' : 'text-sm'
						)}
						title={entry.label}>
						{entry.label}
					</p>

					{entryType === 'gang' && (
						<p className='mt-0.5 text-[11px] text-white/40'>Cấp {entry.level}</p>
					)}
					{entryType === 'player' && entry.level > 0 && (
						<p className='mt-0.5 text-[11px] text-white/40'>Cấp nghề {entry.level}</p>
					)}

					<div className='mt-2 border-t border-white/6 pt-2'>
						<p className='text-[9px] font-semibold uppercase tracking-[0.14em] text-white/35'>
							{valueLabel}
						</p>
						<p className={cn('font-heading text-lg font-extrabold leading-tight', theme.accent)}>
							{formatNumber(entry.value)}
						</p>
					</div>
				</div>
			</div>

			<div className='relative w-full max-w-[108px]'>
				<div
					className={cn(
						'relative flex items-end justify-center overflow-hidden rounded-t-2xl bg-gradient-to-b shadow-[inset_0_1px_0_rgba(255,255,255,0.25)]',
						theme.pedestal,
						theme.pedestalHeight
					)}>
					<span
						className={cn(
							'select-none font-heading text-4xl font-black leading-none',
							theme.number,
							isCenter && 'text-5xl'
						)}>
						{entry.rank}
					</span>
					<div className='pointer-events-none absolute inset-x-0 top-0 h-1/2 bg-gradient-to-b from-white/20 to-transparent' />
				</div>
				<div className='h-1 rounded-b-md bg-black/40' />
			</div>
		</div>
	)
}

export default function Podium({ entries, valueLabel, entryType = 'gang' }: PodiumProps) {
	const top3 = entries.filter((e) => e.rank <= 3)
	if (top3.length === 0) return null

	const ordered = podiumOrder
		.map((rank) => top3.find((e) => e.rank === rank))
		.filter(Boolean) as LeaderboardEntry[]

	return (
		<div className='relative px-5 pb-1 pt-4'>
			<div className='pointer-events-none absolute inset-x-8 bottom-8 top-10 rounded-3xl bg-gradient-to-b from-uls/6 via-transparent to-transparent' />
			<div className='relative flex items-end justify-center gap-2 sm:gap-4'>
				{ordered.map((entry) => (
					<PodiumCard
						key={`${entry.rank}-${entry.name}`}
						entry={entry}
						valueLabel={valueLabel}
						isCenter={entry.rank === 1}
						entryType={entryType}
					/>
				))}
			</div>
			<div className='mx-auto mt-1 h-px max-w-md bg-gradient-to-r from-transparent via-white/10 to-transparent' />
		</div>
	)
}
