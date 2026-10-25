import type { ComponentType } from 'react'
import { cn } from '@/utils'

function CrownIcon({ className }: { className?: string }) {
	return (
		<svg viewBox='0 0 24 24' fill='currentColor' className={className} aria-hidden>
			<path d='M4 18h16v2H4v-2zm1.5-8.2L7 14h10l1.5-4.2 2.2 3.4 1.3-5.6-4 2.5L12 5 9 9.1l-4-2.5 1.3 5.6 2.2-3.3z' />
		</svg>
	)
}

function MedalIcon({ className, rank }: { className?: string; rank: 2 | 3 }) {
	return (
		<svg viewBox='0 0 24 24' fill='none' className={className} aria-hidden>
			<circle cx='12' cy='15' r='5.5' stroke='currentColor' strokeWidth='1.5' fill='currentColor' fillOpacity='0.2' />
			<path
				d='M12 3v4M8.2 5.8l2.8 2.8M15.8 5.8l-2.8 2.8'
				stroke='currentColor'
				strokeWidth='1.5'
				strokeLinecap='round'
			/>
			<text x='12' y='17' textAnchor='middle' fontSize='8' fontWeight='bold' fill='currentColor'>
				{rank}
			</text>
		</svg>
	)
}

const medals: Record<
	1 | 2 | 3,
	{ label: string; badge: string; glow: string; Icon: ComponentType<{ className?: string }> }
> = {
	1: {
		label: 'Vàng',
		badge: 'bg-gradient-to-br from-yellow-300 via-amber-400 to-amber-700 text-yellow-950 shadow-[0_0_14px_rgba(250,204,21,0.5)]',
		glow: 'from-yellow-400/25 via-amber-500/10 to-transparent',
		Icon: CrownIcon,
	},
	2: {
		label: 'Bạc',
		badge: 'bg-gradient-to-br from-slate-100 via-slate-300 to-slate-600 text-slate-900 shadow-[0_0_10px_rgba(203,213,225,0.35)]',
		glow: 'from-slate-300/20 via-slate-400/8 to-transparent',
		Icon: ({ className }) => <MedalIcon className={className} rank={2} />,
	},
	3: {
		label: 'Đồng',
		badge: 'bg-gradient-to-br from-orange-300 via-amber-600 to-orange-900 text-orange-950 shadow-[0_0_10px_rgba(251,146,60,0.35)]',
		glow: 'from-orange-400/20 via-amber-600/8 to-transparent',
		Icon: ({ className }) => <MedalIcon className={className} rank={3} />,
	},
}

interface RankMedalProps {
	rank: 1 | 2 | 3
	size?: 'sm' | 'md'
	showLabel?: boolean
	className?: string
}

export function RankMedal({ rank, size = 'sm', showLabel = false, className }: RankMedalProps) {
	const m = medals[rank]
	const iconSize = size === 'md' ? 'h-5 w-5' : 'h-3.5 w-3.5'
	const boxSize = size === 'md' ? 'h-8 w-8' : 'h-6 w-6'

	return (
		<span className={cn('inline-flex items-center gap-1', className)}>
			<span
				className={cn(
					'flex shrink-0 items-center justify-center rounded-full',
					boxSize,
					m.badge
				)}>
				<m.Icon className={iconSize} />
			</span>
			{showLabel && (
				<span className='text-[9px] font-bold uppercase tracking-wider opacity-90'>{m.label}</span>
			)}
		</span>
	)
}

export function getRankMedalTheme(rank: number) {
	return medals[rank as 1 | 2 | 3]
}
