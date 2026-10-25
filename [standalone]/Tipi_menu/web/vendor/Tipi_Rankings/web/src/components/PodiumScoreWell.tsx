import type { ReactNode } from 'react'
import { cn } from '@/utils'

type PodiumRank = 1 | 2 | 3

const UI_WELL_BASE =
	'from-[rgba(70,38,141,0.48)] via-[rgba(45,28,82,0.72)] to-[rgba(22,16,38,0.9)]'

const wellTheme: Record<
	PodiumRank,
	{ gradient: string; edge: string; label: string; value: string }
> = {
	1: {
		gradient: UI_WELL_BASE,
		edge: 'border-t border-amber-400/30',
		label: 'text-white',
		value: 'text-white',
	},
	2: {
		gradient: UI_WELL_BASE,
		edge: 'border-t border-[#FFFFFF35]',
		label: 'text-white',
		value: 'text-white',
	},
	3: {
		gradient: UI_WELL_BASE,
		edge: 'border-t border-orange-400/25',
		label: 'text-white',
		value: 'text-white',
	},
}

const embeddedWellTheme: Record<PodiumRank, { gradient: string; edge: string }> = {
	1: {
		gradient: UI_WELL_BASE,
		edge: 'border-t border-amber-400/35',
	},
	2: {
		gradient: UI_WELL_BASE,
		edge: 'border-t border-[#00e5ff]/40',
	},
	3: {
		gradient: UI_WELL_BASE,
		edge: 'border-t border-orange-400/30',
	},
}

interface PodiumScoreWellProps {
	rank: PodiumRank
	valueLabel: string
	value: ReactNode
	className?: string
	embedded?: boolean
}

export default function PodiumScoreWell({
	rank,
	valueLabel,
	value,
	className,
	embedded = false,
}: PodiumScoreWellProps) {
	const t = embedded ? embeddedWellTheme[rank] : wellTheme[rank]
	const text = wellTheme[rank]

	return (
		<div
			className={cn(
				'lb-podium-score-well absolute inset-x-[6%] z-10 flex flex-col items-center justify-center overflow-hidden text-center',
				'bg-gradient-to-b',
				t.gradient,
				t.edge,
				'px-1.5 py-1.5',
				className
			)}
			style={{
				bottom: embedded ? '9%' : '7%',
				height: embedded ? '24%' : '22%',
				clipPath: 'polygon(5% 0, 95% 0, 88% 100%, 12% 100%)',
			}}>
			<p
				className={cn(
					'lb-podium-value-label w-full truncate text-[9px] font-extrabold uppercase tracking-[0.1em]',
					embedded ? 'text-[#f3efff]' : text.label,
					'drop-shadow-[0_1px_4px_rgba(0,0,0,0.95)]'
				)}>
				{valueLabel}
			</p>
			<p
				className={cn(
					'lb-podium-value-number w-full truncate font-heading text-[15px] font-extrabold tabular-nums leading-tight',
					embedded ? 'text-[#7fdfff]' : text.value,
					'drop-shadow-[0_1px_4px_rgba(0,0,0,0.9)]'
				)}>
				{value}
			</p>
		</div>
	)
}
